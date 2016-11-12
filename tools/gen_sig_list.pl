#! /usr/bin/perl

use Env;
use Getopt::Long;
use File::Basename;
use Cwd;
use Switch;
use strict;
use Data::Dumper;
use Storable;

my $proj_root = ""; #add your working directory path
my $usage;
my $dump_log;
my $ifile;
my $mod;
my $top;
my $ofile;
my $dump_hier;
my $dump_hier_file = 0;
my $hier_file;
my $hier_top;
my $create_sim_file;
my $wr_sim_file = 0;
my $sim_file;

my @files;
my @units;
my %mod_list;
my %hier;

my %h;
my %hc;
my $p;
my %full_hier;
my $fh = \%full_hier;
my %sig_list;
my @full_sig_list;

my $bcnt=0;
my $scnt=0;

GetOptions ("-help"            => \$usage,
            "-h"               => \$usage,
            "-log"             => \$dump_log,
            "-mod=s"           => \$mod,
            "-i=s"             => \$ifile,
            "-top"             => \$top,
            "-o=s"             => \$ofile,
            "-dump_hier"       => \$dump_hier,
            "-hier_file=s"     => \$hier_file,
            "-create_sim_file"  => \$create_sim_file,
            "-sim_file=s"      => \$sim_file
    );

if(defined $usage) { usage(); };
if(defined $dump_log) { $dump_log = 1; };
if(!(defined $ifile)) { 
    if(!(defined $mod)) { 
        die "Please specify file list\n"; 
    } else {
        $ifile = $proj_root."/rtl/".$mod.".rtl.files";
    };
};
if(!(defined $ofile)) {
    $ofile = "sig_list";
};
if(!(defined $top)) {
    if(!(defined $mod)) {
        $top = $ifile;
        $top =~ s/.*\/(.*)$//;
        $top = $1;
        $top =~ s/\..*$//;
    } else {
        $top = $mod;
    }
    #print $top."\n";
}

if(defined $dump_hier){
    $dump_hier_file = 1;
    if(!(defined $hier_file)) {
        $hier_file = $mod."_hier";
    };
}

if(defined $create_sim_file) {
    $wr_sim_file = 1;
    if(!(defined $sim_file)) {
        $sim_file = "sim.cpp";
    }
}

#-------------------------------------------------------------------------------
#Build file list and hierarchy
#-------------------------------------------------------------------------------

build_file_list();
build_hier_tree();
build_sig_list();
if($wr_sim_file) {
    write_sim_file();
}

#-------------------------------------------------------------------------------
#Build signal list
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
#Functions
#-------------------------------------------------------------------------------


#----------
#Help

sub usage() {
    print "Please stay online while we connect you to our customer care executive!\n";
    exit(1);
}

#----------
#build file list

sub build_file_list {
    gen_list("rtl");
    gen_list("tb");
    #print join "\n" => @files; print "\n";
    
}

sub gen_list {
    
    my $type = @_[0];
    my $file = $proj_root."/".$top."/".$type."/".$top.".".$type.".files";
    #print $file."\n";
    
    my @lines = proc_file($file);
    #print join "\n" => @lines; print "\n";
    foreach my $line (@lines) {
        if($line =~ m/#include\s*/) {
            $line =~ s/#include\s*//;
            $line =~ s/<//;
            $line =~ s/\"//;
            $line =~ s/>$//;
            $line =~ s/"$//;
            chomp($line);
            #print $line."\n";
            $line = $proj_root."/".$top."/".$type."/".$line;
            push(@files, $line);
        }
    }
    my $line;
    if($type eq "rtl") {
        $line = $proj_root."/".$top."/".$type."/".$top.".cpp";
    } else {
        $line = $proj_root."/".$top."/".$type."/".$top."_tb.cpp";
    }
    push(@files, $line);
}

#----------
#build hierarchy tree

sub build_hier_tree {

    my @list = reverse @files;
    my @mlist;

    foreach my $file (@list) {
        print $file."\n";
        my $content;
        my @lines = proc_file($file);
        foreach my $line (@lines) {
            $content = $content.$line;
        }
        $content =~ s/\n/ /g;
        #print $content;
        my $m = $content;
        $m =~ s/.*SC_MODULE\s*\(//;
        #print $m;
        $m =~ s/\).*$//;
        print "Module name in $file is $m \n";
        $mod_list{$m} = $file;
        push(@mlist, $m);
    }
    
    foreach my $m (keys %mod_list) {
        print "$m :: $mod_list{$m}\n";
    }

    foreach my $file (@list) {
        my $content;
        my @lines = proc_file($file);
        foreach my $line (@lines) {
            $content = $content.$line;
        }
        my $cnt;
        $cnt = 0;
        foreach my $line (@lines) {
            #print $line;
            foreach my $m (@mlist) {
                if(($line =~ m/^\s*$m\s*<.*>\s*.*;\s*$/)
                   || ($line =~ m/^\s*$m\s+.*;\s*$/)){
                    #print $m."\n";
                    my $k = $line;
                    $k =~ s/^\s+//;
                    $k =~ s/\s+$//;
                    $k =~ s/;//;
                    $k =~ s/<.*>//;
                    #print $k."\n";
                    $k =~ s/^$m\s+//;
                    $k =~ s/(.*)$//;
                    my $inst = $1;
                    $content =~ s/\n/ /g;
                    my $mname = $content;
                    $mname =~ s/.*SC_MODULE\s*\(//;
                    $mname =~ s/\).*$//;
                    #print "Module name in $file is $mname \n";
                    #print "\tinstance is $inst \n";
                    chomp($line);
                    $k = $line;
                    $k =~ s/^\s+//;
                    $k =~ s/\s+$//;
                    $k =~ s/<.*$/ /;
                    $k =~ s/^(.*)\s+//;
                    $k = $1;
                    $k =~ s/^\s+//;
                    $k =~ s/\s+$//;
                    $h{$mname}{$inst} = $k;
                    #print "$mname -> $inst :: $h{$mname}{$inst} \n";
                    $cnt++;
                }
            }
        }
    }
    print Dumper(\%h);
    
    my @hier_lvl;
    my @tmp;
    my $c = 0;
    foreach my $inst (keys %h) {
        $tmp[$c] = 1;
        foreach my $unit (keys %h) {
            foreach my $m (keys %{$h{$unit}}) {
                if($inst eq $h{$unit}{$m}) {
                    $tmp[$c] = 0;
                }
            }
        }
        #print "$inst ... $tmp[$c]\n";
        $c++;
    }
    
    $c = 0;
    foreach my $inst (keys %h) {
        if($tmp[$c] == 1) {
            $hier_top = $inst;
        }
        $c++;
    }
    print "hierarhical top is $hier_top\n";

    $p = \%hc;

    foreach my $inst (@mlist) {
        $p->{$inst} = {} unless exists($p->{$inst});
    }
    #print Dumper(\%hc);

    foreach my $k (keys $p){
        #print "$k .. $p->{$k} \n";
        $p->{$k} = $h{$k};
    }
    print Dumper(\%hc);
    print "*******************\n";
    
    $p = \%hier;
    my $cnt = 0;
    foreach my $k (keys %{$hc{$hier_top}} ){
        $p->{$hier_top}[$cnt] = $k;
        $cnt++;
    }

    foreach my $k (keys %hc) {
        #print "$k \n";
        foreach my $l (keys %{$hc{$k}}) {
            #print "\t$l .. $hc{$k}{$l} \n";
            my $ecnt = 0;
            foreach my $m (keys %{$h{$hc{$k}{$l}}}) {
                #print $m;
                $p->{$l}[$ecnt] = "$m";
                $ecnt++;
            }
        }
    }
    print "======================================================\n";
    print Dumper(\%hier);
    print "======================================================\n";

    print "Building hierarchy....\n";
    $p = \%hier;
    $fh = \%{$fh->{$hier_top}};
    build_hier(@{$hier{$hier_top}});
    print "======================================================\n";
    print Dumper(\%full_hier);
    print "======================================================\n";
    
    $fh = \%full_hier;
    if($dump_hier_file) {
        open FWP, ">", $hier_file or die "Could not open $hier_file for reading : $!\n";
        print FWP Dumper(\%full_hier);
        close(FWP);
    }

}

sub build_hier {

    my @harr = @_;
    #print join " => " => @harr; print "\n";
    my $link = $fh;

    foreach my $k (@harr) {
        if($p->{$k}) { 
            $fh = \%{$fh->{$k}};
            my @arr = @{$p->{$k}};
            print join " => " => @arr; print "\n";
            build_hier(@arr);
            $fh = $link;
        } else {
            $fh->{$k} = 0;
            #print "end of this line\n";
        }
        $bcnt++;
        if($bcnt == 100000) { print Dumper(\%full_hier); exit(1); } # just a check to ensure script doesnt hang
    }
    return;

}

#----------
#build signal list

sub build_sig_list () {

    print "-----------------------------------------------------\n";
    print Dumper(\%h);
    print "-----------------------------------------------------\n";

    print "-----------------------------------------------------\n";
    print Dumper(\%mod_list);
    print "-----------------------------------------------------\n";

    foreach my $m (keys %mod_list) {
        #print $mod_list{$m}."\n";
        my @lines = proc_file($mod_list{$m});
        my $cnt = 0;
        foreach my $line (@lines) {
            if(($line =~ m/^\s*sc_signal/)
                || ($line =~ m/^\s*sc_in/)
                || ($line =~ m/^\s*sc_out/)
                || ($line =~ m/^\s*sc_inout/)) {
                my $k = $line;
                chomp($line);
                $k =~ s/^\s+//;
                $k =~ s/\s+$//;
                $k =~ s/;//;
                $k =~ s/<.*>//;
                $k =~ s/^sc_signal\s+//;
                $k =~ s/^sc_in\s+//;
                $k =~ s/^sc_out\s+//;
                $k =~ s/^sc_inout\s+//;
                $k =~ s/(.*)$//;
                my $inst = $1;
                #print $inst."\n";
                $sig_list{$m}[$cnt] = $inst;
                $cnt++;
            }
        }
    }
    print Dumper(\%sig_list);

    $fh = \%full_hier;
    $bcnt = 0;
    my $tb_path = $mod."_tb";
    make_full_sig_list($tb_path);
    print "-----------------------------------------------------\n";
    print join "\n" => @full_sig_list; print "\n";
    print "-----------------------------------------------------\n";

    print "Writing signal list to the file \"$ofile\" .... \n";
    open FWP, ">", $ofile or die "Could not open $ofile for reading : $!\n";
    print FWP join "\n" => @full_sig_list; print FWP "\n";
    close(FWP);
	print "Signal list dumped to \"$ofile\" \n";
    print "-----------------------------------------------------\n";


}

sub make_full_sig_list () {
    
    my $can_path = shift;
    my $link = $fh;
    my $cur_can_path = $can_path;

    foreach my $k (keys $fh) {
        my $inst;
        if($fh->{$k} == 0) {
            $inst = get_mod_name($k);
            my @arr = @{$sig_list{$inst}};
            foreach my $sig (@arr) {
                $sig = $cur_can_path.".".$k.".".$sig;
                push(@full_sig_list, $sig);
            }
            $fh = $link;
        } else {
            if($k ne $hier_top) { 
                $inst = get_mod_name($k);
                $can_path = $can_path.".".$k;
            } else {
                $inst = $hier_top;
            }
            my @arr = @{$sig_list{$inst}};
            foreach my $sig (@arr) {
                $sig = $can_path.".".$sig;
                push(@full_sig_list, $sig);
            }
            $fh = \%{$fh->{$k}};
            my $stat = make_full_sig_list($can_path);
            $fh = $link;
            $can_path = $cur_can_path;
        }
    }
    $bcnt++;
    if($bcnt == 100000) { print Dumper(\%full_hier); print "\nlimit hit\n"; exit(1); } # just a check to ensure script doesnt hang
    return 0;

}

sub get_mod_name () {

    my $inst = shift;
    print "$inst \n";

    foreach my $k (keys %h) {
        foreach my $l (keys %{$h{$k}}) {
            if($l eq $inst) {
                return $h{$k}{$l};
            }
        }
    }

}


#---------
#write sim file

sub write_sim_file () {

    my $content;
    $content = sim_header();
    $content .= sim_includes();
    $content .= sim_main();
    $content .= sim_prop();
	$content .= sim_inst();
    $content .= sim_trace();
    $content .= sim_footer();
    
    #print $content;
    
    print "-----------------------------------------------------\n";
	print "Writing sim file sim.cpp ... \n";
    open FWP, ">", $sim_file or die "Could not open $sim_file for reading : $!\n";
    print FWP $content;
    close(FWP);
	print "Done \n";
    print "-----------------------------------------------------\n";

}

sub sim_header() {

    my $header;

    $header  = "/*************************************************************************\n";
    $header .= "*        DO NOT EDIT MANUALLY\n";
    $header .= "**************************************************************************\n";
    $header .= "*   AUTO GENERATED by gen_sig_list.pl\n";
    $header .= "*   Time of generation: ".localtime(time)."\n";;
    $header .= "*************************************************************************/\n";
    $header .= "\n";

    #print $header;
    return $header;

}

sub sim_includes() {

    my $include;

    $include  = "/*************************************************************************\n";
    $include .= "*Include files - systemc libs and project testbench file\n";
    $include .= "*************************************************************************/\n";
    $include .= "#include <systemc.h>\n";
    $include .= "#include <".$mod."_tb.cpp>\n";
    $include .= "//***********************************************************************\n";
    $include .= "\n";

    #print $include;
    return $include;

}

sub sim_main() {

    my $main;

    $main  = "/*************************************************************************\n";
    $main .= "*SC main \n";
    $main .= "*************************************************************************/\n";
    $main .= "int sc_main(int argc, char* argv[])\n";
    $main .= "{\n";
    $main .= "\n";

    #print $main;
    return $main;

}

sub sim_prop() {

    my $prop;

    $prop  = "/*************************************************************************\n";
    $prop .= "*System Time Scale and Resolution Properties \n";
    $prop .= "*************************************************************************/\n";
    $prop .= "  sc_set_time_resolution(1, SC_PS); //set resolution\n";
    $prop .= "  sc_time t1(1, SC_PS);             //set time step\n";
    $prop .= "//************************************************************************\n";
    $prop .= "\n";

    #print $prop;
    return $prop;

}

sub sim_inst() {

    my $inst;

    $inst  = "/*************************************************************************\n";
    $inst .= "*Creating $mod"."_tb instance\n";
    $inst .= "*************************************************************************/\n";
    $inst .= "  $hier_top $mod"."_tb(\"wave\");             //set time step\n";   # FIXME - need to obtain templates first
    $inst .= "//************************************************************************\n";
    $inst .= "\n";

    #print $inst;
    return $inst;

}

sub sim_trace() {

    my $trace;

    $trace  = "/*************************************************************************\n";
    $trace .= "*Trace file (.vcd) and adding signal to trace \n";
    $trace .= "*************************************************************************/\n";
    $trace .= "  sc_trace_file *wf;                      //trace file\n";
    $trace .= "  wf = sc_create_vcd_trace_file(\"sim\");   //sim.vcd is the name of trace file\n";
    $trace .= "\n";
    $trace .= "//--------------------------------------\n";
    $trace .= "//trace signals\n";
    $trace .= "//--------------------------------------\n";
    foreach my $sig (@full_sig_list) {
        $trace .= "  sc_trace(wf, $sig, \"$sig\");\n";
    }
    $trace .= "//--------------------------------------\n";
    $trace .= "\n";
    $trace .= "  sc_start(); //Start trace and dump signal to vcd file\n";
    $trace .= "\n";
    $trace .= "  sc_close_vcd_trace_file(wf); //close trace file\n";
    $trace .= "//************************************************************************\n";
    $trace .= "\n";

    #print $trace;
    return $trace;

}

sub sim_footer() {

    my $footer;

    $footer  = "  return(0);\n";
    $footer .= "}\n";
    $footer .= "/*************************************************************************\n";
    $footer .= "*Number of signals added to trace : $#full_sig_list\n";
    $footer .= "*************************************************************************/\n";

    #print $footer;
    return $footer;

}

#----------------------------------------
#common functions

sub proc_file () {
    
    my $file = shift;
    my @lines; 
    open FRP, "<", $file or die "Could not open $file for reading : $!\n";
    my $cmt_blk = 0;
    my $cmt_line = 0;
    while(my $line = <FRP>) {
        if($cmt_blk == 0) {
            if($line =~ m/^\/\*/) {
                $cmt_blk = 1;
            } elsif($line =~ m/\/\*.*\*\//) {
                $line =~ s/\/\*.*\*\///;
                if($line =~ m/\*\//) {
                    $line =~ s/\/\*.*\*\///;
                }
            } elsif($line =~ m/^\s*\/\//) {
                $cmt_line = 1;
            }
        } elsif($cmt_blk == 1) {
            if($line =~ m/\*\/$/) {
                $cmt_blk == 0;
            }
        }
        #print " ... $cmt_line .. $cmt_blk ... $line \n";
        if($cmt_blk == 0 && $cmt_line == 0) {
            #print $line."\n";
            push(@lines, $line);
        }
        $cmt_line = 0;
    }
    close(FRP);
    return(@lines);
}
