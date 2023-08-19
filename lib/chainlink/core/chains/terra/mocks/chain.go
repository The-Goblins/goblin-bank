// Code generated by mockery v2.14.0. DO NOT EDIT.

package mocks

import (
	context "context"

	client "github.com/smartcontractkit/chainlink-terra/pkg/terra/client"

	db "github.com/smartcontractkit/chainlink-terra/pkg/terra/db"

	mock "github.com/stretchr/testify/mock"

	terra "github.com/smartcontractkit/chainlink-terra/pkg/terra"
)

// Chain is an autogenerated mock type for the Chain type
type Chain struct {
	mock.Mock
}

// Close provides a mock function with given fields:
func (_m *Chain) Close() error {
	ret := _m.Called()

	var r0 error
	if rf, ok := ret.Get(0).(func() error); ok {
		r0 = rf()
	} else {
		r0 = ret.Error(0)
	}

	return r0
}

// Config provides a mock function with given fields:
func (_m *Chain) Config() terra.Config {
	ret := _m.Called()

	var r0 terra.Config
	if rf, ok := ret.Get(0).(func() terra.Config); ok {
		r0 = rf()
	} else {
		if ret.Get(0) != nil {
			r0 = ret.Get(0).(terra.Config)
		}
	}

	return r0
}

// Healthy provides a mock function with given fields:
func (_m *Chain) Healthy() error {
	ret := _m.Called()

	var r0 error
	if rf, ok := ret.Get(0).(func() error); ok {
		r0 = rf()
	} else {
		r0 = ret.Error(0)
	}

	return r0
}

// ID provides a mock function with given fields:
func (_m *Chain) ID() string {
	ret := _m.Called()

	var r0 string
	if rf, ok := ret.Get(0).(func() string); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(string)
	}

	return r0
}

// Reader provides a mock function with given fields: nodeName
func (_m *Chain) Reader(nodeName string) (client.Reader, error) {
	ret := _m.Called(nodeName)

	var r0 client.Reader
	if rf, ok := ret.Get(0).(func(string) client.Reader); ok {
		r0 = rf(nodeName)
	} else {
		if ret.Get(0) != nil {
			r0 = ret.Get(0).(client.Reader)
		}
	}

	var r1 error
	if rf, ok := ret.Get(1).(func(string) error); ok {
		r1 = rf(nodeName)
	} else {
		r1 = ret.Error(1)
	}

	return r0, r1
}

// Ready provides a mock function with given fields:
func (_m *Chain) Ready() error {
	ret := _m.Called()

	var r0 error
	if rf, ok := ret.Get(0).(func() error); ok {
		r0 = rf()
	} else {
		r0 = ret.Error(0)
	}

	return r0
}

// Start provides a mock function with given fields: _a0
func (_m *Chain) Start(_a0 context.Context) error {
	ret := _m.Called(_a0)

	var r0 error
	if rf, ok := ret.Get(0).(func(context.Context) error); ok {
		r0 = rf(_a0)
	} else {
		r0 = ret.Error(0)
	}

	return r0
}

// TxManager provides a mock function with given fields:
func (_m *Chain) TxManager() terra.TxManager {
	ret := _m.Called()

	var r0 terra.TxManager
	if rf, ok := ret.Get(0).(func() terra.TxManager); ok {
		r0 = rf()
	} else {
		if ret.Get(0) != nil {
			r0 = ret.Get(0).(terra.TxManager)
		}
	}

	return r0
}

// UpdateConfig provides a mock function with given fields: _a0
func (_m *Chain) UpdateConfig(_a0 *db.ChainCfg) {
	_m.Called(_a0)
}

type mockConstructorTestingTNewChain interface {
	mock.TestingT
	Cleanup(func())
}

// NewChain creates a new instance of Chain. It also registers a testing interface on the mock and a cleanup function to assert the mocks expectations.
func NewChain(t mockConstructorTestingTNewChain) *Chain {
	mock := &Chain{}
	mock.Mock.Test(t)

	t.Cleanup(func() { mock.AssertExpectations(t) })

	return mock
}