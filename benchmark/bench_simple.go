package main

import (
	"math/rand"

	"github.com/apple/foundationdb/bindings/go/src/fdb"
	"github.com/apple/foundationdb/bindings/go/src/fdb/tuple"
	"github.com/google/uuid"
)

// rand seed
var (
	r = rand.New(rand.NewSource(42))
)

func newKey(prefix int) tuple.Tuple {
	id := uuid.New()
	buf := [16]byte(id)
	return tuple.Tuple{BitgnPrefix, prefix, buf[:]}
}

func benchSimple(db fdb.Database) error {

	write := r.Intn(100) < 20

	if write {
		_, err := db.Transact(func(tr fdb.Transaction) (interface{}, error) {
			key := newKey(1)
			value := make([]byte, 200)
			tr.Set(key, value)
			return nil, nil
		})
		return err
	}

	_, err := db.ReadTransact(func(tr fdb.ReadTransaction) (interface{}, error) {

		key := newKey(1)
		_, err := tr.Get(key).Get()
		return nil, err
	})

	return err
}
