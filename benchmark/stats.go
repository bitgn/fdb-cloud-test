package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/codahale/hdrhistogram"
)

const (
	frequencySec = 6
)

var (
	statsFile = flag.String("stats", "stats.tsv", "statistics file")
)

func mustOpenFile(name string) *os.File {
	f, err := os.OpenFile(name, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Fprintf(f, "# %s %s\n", time.Now().Format("2006-01-02 15:04:05"), os.Args)
	return f
}

func printLine(f *os.File, args ...interface{}) {
	for i, v := range args {
		if i > 0 {
			f.WriteString("\t")
		}
		fmt.Fprint(f, v)
	}
	f.WriteString("\n")
}

func stats(ms chan metrics) {
	freq := time.Duration(frequencySec) * time.Second
	timer := time.NewTicker(freq).C
	latencyMs := hdrhistogram.New(0, 50000, 3)

	begin := time.Now()

	f := mustOpenFile(*statsFile)
	defer f.Close()
	printLine(f, "Seconds", "TxTotal", "TxDelta", "ErrDelta", "Hz", "P50", "P90", "P99", "P999", "100")

	fmt.Println("     Sec      Hz      Total     Err   P90 ms   P99 ms   MAX ms")

	var (
		txTotal, txDelta   int64
		errTotal, errDelta int64
	)

	for {
		select {
		case <-timer:

			secTotal := int64(time.Since(begin).Seconds())
			hz := int(txDelta / frequencySec)

			fmt.Printf("%8d %7d %10d %7d %8d %8d %8d\n",
				secTotal, hz, txTotal, errTotal,
				latencyMs.ValueAtQuantile(90),
				latencyMs.ValueAtQuantile(99),
				latencyMs.ValueAtQuantile(100),
			)
			printLine(f, secTotal,
				txTotal, txDelta,
				errDelta, hz,
				latencyMs.ValueAtQuantile(50),
				latencyMs.ValueAtQuantile(90),
				latencyMs.ValueAtQuantile(99),
				latencyMs.ValueAtQuantile(99.9),
				latencyMs.ValueAtQuantile(100),
			)
			// TODO: gather cluster size

			txDelta, errDelta = 0, 0
			latencyMs.Reset()

		case m := <-ms:
			ms := m.nanoseconds / int64(time.Millisecond)
			latencyMs.RecordValue(ms)
			if m.error {
				errDelta++
				errTotal++
			} else {
				txDelta++
				txTotal++
			}

		}
	}

}
