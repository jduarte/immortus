Immortus Details
===

Since it's mandatory to be used at least one verify method, so we can check if the job is finished, we created one, doe to convenience, and from now on we will call it __default verify__

In this section we are specifying 3 ways of dealing with things:

- [Minimalistic](minimalistic.md) ( more syntactic sugar / hidden behavior ) - we assume you already have jobs created and just need to know when they finish and just want to change the minimum possible
- [Intermediate](intermediate.md) - we assume you will create a new background job with an extra field (percentage)
- [Explicit](explicit.md) ( clear as water ) - have full control on what is going on doing the same as Intermediate way

In your use case you can mix some of these,
this is just a detailed example to try to avoid doubts on how should you do things with `Immortus`.
