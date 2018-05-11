package main

import (
	"flag"
	"fmt"
	"time"

	"github.com/apple/foundationdb/bindings/go/src/fdb"
	"github.com/apple/foundationdb/bindings/go/src/fdb/tuple"
)

var (
	actors = flag.Int("actors", 1000, "number of actors to run")
	writes = flag.Int("writes", 20, "percent of writes")
)

func main() {

	flag.Parse()

	command := "help"
	if flag.NArg() == 1 {
		command = flag.Arg(0)
	}

	fdb.MustAPIVersion(510)
	db := fdb.MustOpenDefault()

	switch command {

	case "clear":
		clear(db)

	case "simple":

		ms := make(chan metrics, 200000)

		for i := 0; i < *actors; i++ {
			go benchmark(ms, db, benchSimple)
		}

		stats(ms)
	default:
		help()
		return
	}
}

func help() {
	fmt.Println("FoundationDB benchmark tool")
	fmt.Println("Usage: benchmark [flags] command")
	fmt.Println("Flags:")
	flag.PrintDefaults()
}

type metrics struct {
	nanoseconds int64
	error       bool
}

type action func(db fdb.Database) error

var BitgnPrefix = "bgn"

func clear(db fdb.Database) {

	err, _ := db.Transact(func(tr fdb.Transaction) (interface{}, error) {

		t := tuple.Tuple{BitgnPrefix}
		r, _ := fdb.PrefixRange(t.Pack())

		tr.ClearRange(r)
		return nil, nil
	})

	if err != nil {
		panic(err)
	}
}

func benchmark(out chan metrics, db fdb.Database, act action) {
	for {
		begin := time.Now()
		err := act(db)
		total := time.Since(begin)

		result := metrics{
			error:       err != nil,
			nanoseconds: total.Nanoseconds(),
		}
		out <- result
	}
}
