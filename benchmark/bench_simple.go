package main

import (
	"github.com/apple/foundationdb/bindings/go/src/fdb"
)

// rand seed

func benchSimple(db fdb.Database) error {

	write := r.Intn(100) < *writes

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
