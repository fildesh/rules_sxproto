# Sxproto Rules for Bazel

Do you want to write structured data in a Lisp-like syntax?
Is your build system fast and correct?
If so, you might like this project's Bazel rule named `sxproto_data()`.

Sxproto (pronounced "ess ex proto") is [an S-expression file format for protocol buffer messages](https://grencez.dev/2022/sxproto-20220122/).
Our `sxproto_data()` Bazel rule compiles one of these `.sxpb` files into a binary protobuf (`.binpb`).
See [example/BUILD.bazel](example/BUILD.bazel) for how to use it with the next section's examples!

## Format

As you might expect, the sxproto file format is pretty simple.
You can basically be an expert after reading through a handful of examples.

**Comments.**
In Lisp, comments are semicolons, so sxproto files do the same.
In fact, we can put the following comment at the end of a sxproto file to tell Vim that it should have Lisp indentation.
```lisp
; vim: ft=lisp lw=nil
```

**Scalar fields.**
These are fields that contain a number or a string.
Fields all have names, so the name should begin the S-expression and the value comes after it.
```lisp
; An integer.
(i 5)
; A float.
(f 5.5)
; A string.
(s "hello")
```

**Message fields.**
These are written the same as scalars.
The field name comes first in the S-expression, and everything after it represents the fields of the message.
Since each field of that message is an S-expression itself, there's no ambiguity.
```lisp
; An message holding a single string.
(m (s "hello"))

; An empty message.
(m)

; A message holding the first 3 fields of the previous example.
(m (i 5) (f 5.5) (s "hello"))
```

**Array fields.**
Rather than holding just one value of a certain type, a repeated field holds an array of such values.
Conceptually, an array is a funny message with no field names, so we put `(())` where the first field would be.
For message elements, we put an empty S-expression `()` where the name would be.
```lisp
; An array of integers.
(my_integers (()) 1 2 3)

; An array of strings.
(my_strings (()) "yo" "howdy" "sup")

; An array of messages.
(my_messages (())
 (() (i 5))
 ()
 (() (i 5) (f 5.5) (s "hello"))
)
```
