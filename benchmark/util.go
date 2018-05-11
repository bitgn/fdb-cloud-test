package main

import (
	"math/rand"

	"github.com/apple/foundationdb/bindings/go/src/fdb/tuple"
	"github.com/google/uuid"
)

var (
	r = rand.New(rand.NewSource(42))
)

func newKey(prefix int) tuple.Tuple {
	id := uuid.New()
	buf := [16]byte(id)
	return tuple.Tuple{BitgnPrefix, prefix, buf[:]}
}
