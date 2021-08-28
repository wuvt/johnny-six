package main

import (
	"bufio"
	"flag"
	"fmt"
	"log"
	"net/url"
	"os"
	"regexp"
)

func main() {
	var destPath string

	flag.StringVar(&destPath, "base", "/srv/automation/", "destination base path to use for files in playlist")
	flag.Parse()

	path := flag.Arg(0)

	if len(path) <= 0 {
		fmt.Fprintf(os.Stderr, "A path to a playlist M3U file must be provided as the first non-flag argument.\n")
		os.Exit(1)
	}

	automationRegexp, err := regexp.Compile("^.*/automation/")
	if err != nil {
		log.Fatal(err)
	}

	f, err := os.Open(path)
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		line, err = url.PathUnescape(line)
		if err != nil {
			panic(err)
		}
		line = automationRegexp.ReplaceAllString(line, destPath)
		fmt.Println(line)
	}

	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}
}
