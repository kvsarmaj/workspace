CC = gcc
CFLAGS =

TARGET=prefetch_addr_gen
SRCS=$(wildcard *.c)
OBJS=$(SRCS:.c=.o)

all: clean $(TARGET) run

run:
	./$(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS)

.c: .o
	$(CC) $(CFLAGS) -x $< -o $@

clean:
	rm -f *.o $(TARGET)
