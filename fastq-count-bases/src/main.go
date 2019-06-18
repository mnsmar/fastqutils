package main

import (
	"bufio"
	"fmt"
	"io"
	"log"
	"os"

	"github.com/alexflint/go-arg"
)

// Opts is the struct with the program command line options.
type Opts struct {
	Fastq string `arg:"required,help:FASTQ file or - to read from STDIN"`
}

// Version returns the program version.
func (Opts) Version() string {
	return "fastq-count-bases 0.1"
}

// Description returns an extended description of the program.
func (Opts) Description() string {
	return "Count the total number of bases (nucleotides) in a FASTQ file."
}

func main() {
	var opts Opts
	arg.MustParse(&opts)

	var err error
	var f *os.File
	if opts.Fastq == "-" {
		f = os.Stdin
	} else {
		if f, err = os.Open(opts.Fastq); err != nil {
			log.Fatal("error: " + err.Error())
		}
	}

	r := bufio.NewReader(f)

	var line []byte
	var inSeq, inQual bool
	var bases int
	for {
		buff, isPrefix, err := r.ReadLine()
		if err != nil {
			if err == io.EOF {
				break
			} else {
				log.Fatal(err)
			}
		}
		line = append(line, buff...)
		if isPrefix {
			continue
		}

		if len(line) == 0 {
			continue
		}

		switch {
		case line[0] == '@':
			inSeq = true
		case inSeq:
			bases += len(line)
			inSeq = false
		case line[0] == '+':
			inQual = true
		case inQual:
			inQual = false
		}
		line = line[:0]
	}

	if err = f.Close(); err != nil {
		log.Fatal(err)
	}

	fmt.Printf("%d\n", bases)
}
