---
layout: post
title: Finding the optional truth
tags: c++ std::optional
---

Using a programming language *can* be an easy task[^1]. Understanding it deeply
and mastering it, though, is more challenging. Multiple definitions of the word
apply here: *demanding* and *stimulating*.

[^1]: Depending on which one you pick, of course.

I have been trying to utilize all available features of C++ as much as possible.
One that I particularly like is `std::optional`[^2]. I am fond of its semantics.
Here is something that may contain a value, or it may as well contain nothing.
This *nothing* is also known as `std::nullopt`. `std::optional` removes the need
of returning raw pointers and relying on comparisons with `nullptr` in order to
check if the return value of a function is valid or not.

[^2]: See [cppreference.com/.../optional](https://en.cppreference.com/w/cpp/utility/optional).

I must say I have not been using `std::optional` extensively, so I am yet to
discover all its edges. But recently, I had to interact with it a little more
and learned something along the way.

## The Pseudocode

Let's start by writing a small example to describe my thought process.

``` c++
#include <string>
#include <optional>

std::optional<std::string> ParseMessage(const std::string& msg)
{
    if (msg.empty())
    {
        return std::nullopt;
    }
    return msg;
}

int main()
{
    auto myMsg = ParseMessage("Hello World");
}
```

The most explicit way to print the above message is:

``` c++
if (myMsg.has_value())
{
    std::cout << myMsg.value() << "\n";
}
```

Of course, in this small example, we could have skipped the check. But in the
real world, we always have to ensure that the value is there. Otherwise, an
exception -- when using `.value()` -- or undefined behavior -- when directly
dereferencing the `std::optional` -- is on the table.

Knowing all these, I filled my code with `.has_value()` and `.value()` calls. I
knew it was correct, but it was also quite cumbersome. There must have been an
easier way to write this.

Looking online, I saw some examples that were doing something akin to:

``` c++
if (myMsg)
{
    std::cout << *myMsg << "\n";
}
```

This is what I was looking for. Not only is this a lot simpler to write, but it
permits you to reuse old code that uses the *nullptr-for-no-value* pattern,
just by changing the type from `T*` to `std::optional<T>` in the code.

Equipped with my newly found knowledge, I removed all calls to `has_value()` and
replaced all calls to `value()` with direct dereferencing using `operator*`.

## The Surprise

Unfortunately, I was greeted with a compiler error.

```
error: cannot convert 'std::optional<T>' to 'bool'
```

The code in question was trying to do something like the following:

``` c++
void Check(bool value);

void Run()
{
    ...
    Check(myOptionalValue);
    ...
}
```

The message was clear. But why did it not work? Converting to a
`bool` in the condition of the `if` statement is certainly possible.

## The Truth

It turns out -- as always -- this is all by design. To answer my questions, I
had to read the available specification on *cppreference.com* a little more
carefully.

> When an object of type optional\<T\> is **contextually converted to bool** [^3],
> the conversion returns true if the object contains a value and false if it
> does not contain a value.

[^3]: See [cppreference.com/.../language/implicit\_conversion](https://en.cppreference.com/w/cpp/language/implicit_conversion).

I was not sure what **"contextually"** meant, so I followed the link, and
I was presented with the following introductory text.

> **Implicit conversions** are performed whenever an expression of some type T1 is used in context that does not accept that type, but accepts some other type T2; in particular:
> - when the expression is used as the **argument** when calling a function that is declared with T2 as parameter;
> - when the expression is used as an **operand** with an operator that expects T2;
> - when **initializing** a new object of type T2, including return statement in a function returning T2;
> - when the expression is used in a **switch** statement (T2 is integral type);
> - when the expression is used in an **if** statement or a **loop** (T2 is bool).

It seemed to explain my situation. The last bullet must be what permits the
usage of `std::optional` in `if` statements.

But wait a minute.

The first bullet should cover the function parameter scenario, too. Obviously,
this was not the case. I was missing something.

The magic word is **"implicit"**.

The `std::optional` class defines the following conversion function to
`bool`:

``` c++
constexpr explicit operator bool() const noexcept
```

It is clearly marked as `explicit`, so implicit conversions do not consider it.

I thought to myself:

> How, then, does the conversion to 'bool' take place in the 'if' condition?

I had to keep reading. Further below was the answer to my question about the
meaning of **"contextually"**.

> **Contextual conversions**
>
> In the following contexts, the type 'bool' is expected and the implicit
conversion is performed if the declaration 'bool t(e)' is well-formed (that is,
an explicit conversion function such as 'explicit T::operator bool() const' is
considered). Such expression 'e' is said to be **contextually converted to
bool**.
>
> Since C++11:
> - the controlling expression of **if**, **while**, **for**
> - the operands of the built-in logical operators **!**, **&&** and **\|\|**
> - the first operand of the conditional operator **?:**
> - the predicate in a **static_assert** declaration
> - the expression in a **noexcept** specifier
>
> Since C++20:
> - the expression in an **explicit** specifier

It turns out that, when a boolean expression is required for defining a
condition -- one would say, in a *conditional context* --, explicit conversion
functions to `bool` are considered as well.

## The Lesson

I don't want to focus on the minefield that is modern C++ syntax and rules.
People smarter and more knowledgeable than me have expressed, and will continue
to express, their opinions on the language. All I want to say is that, as a
deeply inquiring mind, I was quite fascinated to discover this little sub-rule,
which ultimately expanded my knowledge.
