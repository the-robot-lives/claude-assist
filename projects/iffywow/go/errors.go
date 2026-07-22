package ithkuil

import "fmt"

// Error is the error type for every fallible operation in this package.
// Code is a stable machine-readable identifier from the SDK-INTERFACE.md §3
// registry (shared with conformance/invalid_inputs.jsonl); Detail is a
// human-readable explanation and is NOT normative — callers must branch on
// Code (or errors.Is against a sentinel), never on Detail text.
type Error struct {
	Code   string // stable machine-readable code (SDK-INTERFACE.md §3)
	Detail string // human-readable detail; non-normative
}

// Error renders as "<code>: <detail>" (or just the code when the detail is
// empty), matching the message convention of the Python reference codec.
func (e *Error) Error() string {
	if e.Detail == "" {
		return e.Code
	}
	return e.Code + ": " + e.Detail
}

// Is reports whether target is an *Error carrying the same Code, so
//
//	errors.Is(err, ithkuil.ErrDuplicateSocket)
//
// matches any duplicate_socket error regardless of its detail text.
func (e *Error) Is(target error) bool {
	t, ok := target.(*Error)
	return ok && t != nil && t.Code == e.Code
}

// Sentinel errors, one per registry code (SDK-INTERFACE.md §3). Codes are
// permanent: add, never rename. Use with errors.Is; returned errors carry a
// detail string but compare equal to these sentinels by Code.
var (
	ErrInvalidNaturalNumber = &Error{Code: "invalid_natural_number"}
	ErrNonminimalVarint     = &Error{Code: "nonminimal_varint"}
	ErrReservedTag          = &Error{Code: "reserved_tag"}
	ErrUnknownTag           = &Error{Code: "unknown_tag"}
	ErrTruncated            = &Error{Code: "truncated"}
	ErrTrailingBytes        = &Error{Code: "trailing_bytes"}
	ErrInvalidVersion       = &Error{Code: "invalid_version"}
	ErrInvalidOrientation   = &Error{Code: "invalid_orientation"}
	ErrInvalidSocketID      = &Error{Code: "invalid_socket_id"}
	ErrDuplicateSocket      = &Error{Code: "duplicate_socket"}
	ErrUnsortedSockets      = &Error{Code: "unsorted_sockets"}
	ErrInvalidStructure     = &Error{Code: "invalid_structure"}
	ErrUnsupported          = &Error{Code: "unsupported"}
)

// errf builds an *Error carrying the sentinel's Code and a formatted detail.
func errf(sentinel *Error, format string, args ...interface{}) *Error {
	return &Error{Code: sentinel.Code, Detail: fmt.Sprintf(format, args...)}
}
