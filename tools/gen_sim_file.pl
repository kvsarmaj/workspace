#! /usr/bin/perl

use Env;
use Getopt::Long;
use File::Basename;
use Cwd;
use Switch;
use strict;
use Data::Dumper;
use Storable;

my $proj_root = "${PROJ_SC_HOME}";
my $ws_root = "${WS_ROOT}";
my $short_help;
my $usage;
my $dump_log;
my $log_file;
my $log_fname;
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
my $sel_depth;
my $inc_list;

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
my $search_inc=0;

GetOptions ("-help"            => \$usage,
            "-h"               => \$short_help,
            "-log"             => \$dump_log,
			"-log_file"        => \$log_fname,
            "-mod=s"           => \$mod,
            "-i=s"             => \$ifile,
            "-top"             => \$top,
            "-o=s"             => \$ofile,
            "-sel_depth=s"     => \$sel_depth,
            "-dump_hier"       => \$dump_hier,
            "-hier_file=s"     => \$hier_file,
            "-create_sim_file" => \$create_sim_file,
            "-sim_file=s"      => \$sim_file,
            "-inc_list=s"      => \$inc_list
    );

if(defined $short_help) { short_help(); exit(1); };
if(defined $usage) { short_help(); usage(); exit(1); };
if(defined $dump_log) { $dump_log = 1; };
if(!(defined $log_fname))  { $log_fname = "gen_sim_file.log"; }
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
    $log_file .= $top."\n";
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

if(!(defined $sel_depth)) {
    $sel_depth = 0;
}

if(defined $inc_list) {
    $search_inc = 1;
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
if($dump_log) {
	print "Writing log file...\n";
    open FWP, ">", $log_fname or die "Could not open $log_fname for reading : $!\n";
    print FWP $log_file;
	print "...done\n";
    close(FWP);	
}

#-------------------------------------------------------------------------------
#Build signal list
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
#Functions
#-------------------------------------------------------------------------------


#----------
#Help

sub short_help() {
    print " gen_sim_file.pl -help|-h|-mod=|-i= [-log] [-top] [-o=] [-sel_depth=] \n";
    print "                 [-dump_hier] [-hier_file=] [-create_sim_file] [-sim_file=] [-inc_list=] \n";
}

sub usage() {
    print "\n";
    print "   -h                    short usage\n";
    print "   -help                 detailed help\n";
    print "   -log                  dumps log file from the script\n";
	print "   -log_file             specify name of the log file\n";
	print "                         defaults to gen_sim_file.log\n";
    print "   -mod=                 specify module name for building file list\n";
    print "   -i=                   specify you own file list - must be complete list to generate sim file correctly\n";
    print "   -top                  specify top of the hierarchy instantiated in sim.cpp\n";
    print "                           script is generally capable of figuring this out\n";
    print "                           where it fails to do so, specify the top module name\n";
    print "   -o                    specify output file name to dump the signale list\n";
    print "                           when not provided, defaults to sig_list\n";
    print "   -sel_depth            specify hierarchy depth as +ve integer for signal list to be traced\n";
    print "                           when not specified, defaults to 0 i.e., full depth\n";
    print "   -dump_hier            specify if hierarchy file has to be dumped\n";
    print "                           filename specified by -hier_file option\n";
    print "   -hier_file            specify file where hierarchy has to be dumped\n";
    print "                           when not specified, <mod>_hier will be used\n";
    print "                           where <mod> is not specified, top_hier will be used\n";
    print "   -create_sim_file      creates simulation top which initiates simulation\n";
    print "   -sim_file=            specify file name for simulation top which initiates simulation\n";
    print "                           when not specified, defaults to sim.cpp\n";
    print "   -inc_list=            specify included directories \n";
    print "                           preferable when component includes other components/projects\n";
    print "\n";

}

#----------
#build file list

sub build_file_list {
    my $fname;

	$inc_list =~ s/-I//g;
	$log_file .= "Looking in included directories for hierarchy parsing \n";

	my @dirs = split(/\s/,$inc_list);
	foreach my $t (@dirs) {
		$log_file .= "\t".$t."\n";
		opendir my $dir, $t or die "Cannot open directory : $!";
		my @flist = readdir $dir;
		closedir $dir;
		$log_file .= "\t\tFiles found for hierarchy parsing:\n";
		foreach my $f (@flist) {
			if($f =~ m/.cpp$/) {
				my $fn = $t."/".$f;
				$log_file .= "\t\t".$fn."\n";
				push(@files, $fn);
			}
		}
	}
}

#----------
#build hierarchy tree

sub build_hier_tree {

    my @list = reverse @files;
    my @mlist;

    foreach my $file (@list) {
        #print $file."\n";
        my $content;
        my @lines = proc_file($file);
        foreach my $line (@lines) {
            $content = $content.$line;
        }
        $content =~ s/\n/ /g;
        my $m = $content;
        $m =~ s/.*SC_MODULE\s*\(//;
        $m =~ s/\).*$//;
        $log_file .= "Module name in $file is $m \n";
        $mod_list{$m} = $file;
        push(@mlist, $m);
    }

    foreach my $m (keys %mod_list) {
        $log_file .= "$m :: $mod_list{$m}\n";
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
            foreach my $m (@mlist) {
                if(($line =~ m/^\s*$m\s*<.*>\s*.*;\s*$/)
                   || ($line =~ m/^\s*$m\s+.*;\s*$/)){
                    my $k = $line;
                    $k =~ s/^\s+//;
                    $k =~ s/\s+$//;
                    $k =~ s/;//;
                    $k =~ s/<.*>//;
                    $k =~ s/^$m\s+//;
                    $k =~ s/(.*)$//;
                    my $inst = $1;
                    $content =~ s/\n/ /g;
                    my $mname = $content;
                    $mname =~ s/.*SC_MODULE\s*\(//;
                    $mname =~ s/\).*$//;
                    $log_file .= "Module name in $file is $mname \n";
                    $log_file .= "\tinstance is $inst \n";
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
    $log_file .= "hierarhical top is $hier_top\n";
	print "Hierarchical top is $hier_top\n";

    $p = \%hc;

    foreach my $inst (@mlist) {
        $p->{$inst} = {} unless exists($p->{$inst});
    }
    #print Dumper(\%hc);

    foreach my $k (keys %hc){
        $p->{$k} = $h{$k};
    }
	$log_file .= "*******************\n";
	$log_file .= "Identified module and submodule hiearchical components\n";
	$log_file .=  Dumper(\%h);
	$log_file .= "*******************\n";

    $p = \%hier;
    my $cnt = 0;
    foreach my $k (keys %{$hc{$hier_top}} ){
        $p->{$hier_top}[$cnt] = $k;
        $cnt++;
    }

    foreach my $k (keys %hc) {
        foreach my $l (keys %{$hc{$k}}) {
            my $ecnt = 0;
            foreach my $m (keys %{$h{$hc{$k}{$l}}}) {
                $p->{$l}[$ecnt] = "$m";
                $ecnt++;
            }
        }
    }
    $log_file .= "======================================================\n";
	$log_file .= "Finalized hierarchical instances\n";
	$log_file .= Dumper(\%hier);
    $log_file .= "======================================================\n";

	$log_file .= "Building hierarchy....\n";
    print "Building hierarchy....\n";
    $p = \%hier;
    $fh = \%{$fh->{$hier_top}};
    build_hier(@{$hier{$hier_top}});
    $log_file .= "======================================================\n";
	$log_file .= "Hierarchy parsing done\n";
    $log_file .= Dumper(\%full_hier);
    $log_file .= "======================================================\n";
    print "======================================================\n";
	print "Hierarchy parsing done\n";
    print Dumper(\%full_hier);
    print "======================================================\n";

    $fh = \%full_hier;
    if($dump_hier_file) {
		print "Dumping hierarchy file ...\n";
        open FWP, ">", $hier_file or die "Could not open $hier_file for reading : $!\n";
        print FWP Dumper(\%full_hier);
        close(FWP);
		print "...done\n";
    }
}

sub build_hier {

    my @harr = @_;
    my $link = $fh;

    foreach my $k (@harr) {
        if($p->{$k}) {
            $fh = \%{$fh->{$k}};
            my @arr = @{$p->{$k}};
            #print join " => " => @arr; print "\n";
            build_hier(@arr);
            $fh = $link;
        } else {
            $fh->{$k} = 0;
        }
        $bcnt++;
		if($bcnt == 100000) { 
			$log_file .= Dumper(\%full_hier);
			$log_file .= "\n limit hit\n";
			print Dumper(\%full_hier); 
			print "\nlimit hit\n"; 
			exit(1); 
		} # just a check to ensure script doesnt hang
    }
    return;
}

#----------
#build signal list

sub build_sig_list () {

    $log_file .= "Obtaing signal list for each hierarchical instance\n";
	
    $log_file .= "Hierarhical instances and associated modules are ... \n";
	$log_file .= "-----------------------------------------------------\n";
    $log_file .= Dumper(\%h);
    $log_file .=  "-----------------------------------------------------\n";
    $log_file .= "Looking for signals in following files for each module instance\n";
    $log_file .= "-----------------------------------------------------\n";
    $log_file .= Dumper(\%mod_list);
    $log_file .= "-----------------------------------------------------\n";

    foreach my $m (keys %mod_list) {
        $log_file .= "\nLooking in ".$mod_list{$m}."\n";
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
	$log_file .= "-----------------------------------------------------\n";
	$log_file .= "Identified signals in each module\n";
    $log_file .= Dumper(\%sig_list);
	$log_file .= "-----------------------------------------------------\n";

    $fh = \%full_hier;
    $bcnt = 0;
    my $tb_path = $mod."_tb";
    print "-----------------------------------------------------\n";
	print "Obtaining full signal list...\n";
    make_full_sig_list($tb_path);
    $log_file .= "-----------------------------------------------------\n";
	$log_file .= "Obtained full signal list\n";
	foreach my $s (@full_sig_list) {
		$log_file .= "\t".$s."\n";
	}
    $log_file .= "-----------------------------------------------------\n";
	print "...done\n";
    print "-----------------------------------------------------\n";

    $log_file .= "Writing signal list to the file \"$ofile\" .... \n";
    print "Writing signal list to the file \"$ofile\" .... \n";
    open FWP, ">", $ofile or die "Could not open $ofile for reading : $!\n";
    print FWP join "\n" => @full_sig_list; print FWP "\n";
    close(FWP);
    $log_file .= "...done\n";
    $log_file .= "-----------------------------------------------------\n";
    print "...done\n";
    print "-----------------------------------------------------\n";


}

sub make_full_sig_list () {

    my $can_path = shift;
    my $link = $fh;
    my $cur_can_path = $can_path;

    foreach my $k (keys %{$fh}) {
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
    if($bcnt == 100000) { 
		$log_file .= Dumper(\%full_hier);
		$log_file .= "\n limit hit\n";
		print Dumper(\%full_hier); 
		print "\nlimit hit\n"; 
		exit(1); 
	} # just a check to ensure script doesnt hang
    return 0;

}

sub get_mod_name () {

    my $inst = shift;

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

    $log_file .= "-----------------------------------------------------\n";
    $log_file .= "Writing sim file $sim_file ... \n";
    print "-----------------------------------------------------\n";
    print "Writing sim file $sim_file ... \n";
    open FWP, ">", $sim_file or die "Could not open $sim_file for reading : $!\n";
    print FWP $content;
    close(FWP);
    print  "...done \n";
    print  "-----------------------------------------------------\n";
    $log_file .= "...done \n";
    $log_file .= "-----------------------------------------------------\n";

}

sub sim_header() {

    my $header;

    $header  = "/*************************************************************************\n";
    $header .= "*        DO NOT EDIT MANUALLY\n";
    $header .= "**************************************************************************\n";
    $header .= "*   AUTO GENERATED by gen_sim_file.pl\n";
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
