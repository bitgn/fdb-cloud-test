package main

import (
	"fmt"
	"time"
)

const (
	frequencySec = 6
)

func stats(ms chan metrics) {
	freq := time.Duration(frequencySec) * time.Second
	timer := time.NewTicker(freq).C

	begin := time.Now()

	var (
		accumulated int64
		errors      int64
	)

	for {
		select {
		case <-timer:
			seconds := int64(time.Since(begin).Seconds())
			hz := int(accumulated / seconds)
			fmt.Printf("Time: %d   %d Hz  %d errors\n", seconds, hz, errors)
			// TODO: gather cluster size

			accumulated = 0
			errors = 0

		case m := <-ms:
			if m.error {
				errors++
			} else {
				accumulated++
			}

		}
	}

}
