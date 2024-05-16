# Contributing

Thanks for stopping by! This document should cover most topics surrounding contributing to `bugsnag-cocoa-performance`.

* [How to contribute](#how-to-contribute)
  * [Reporting issues](#reporting-issues)
  * [Fixing issues](#fixing-issues)
  * [Adding features](#adding-features)

## Reporting issues

Are you having trouble getting started? Please [contact us directly](mailto:support@bugsnag.com?subject=%5BGitHub%5D%20bugsnag-cocoa-performance%20-%20having%20trouble%20getting%20started%20with%20BugSnag) 
for assistance with integrating BugSnag into your application.  If you have 
spotted a problem with this module, feel free to open a 
[new issue](https://github.com/bugsnag/bugsnag-cocoa-performance/issues/new?template=Bug_report.md). 
Here are a few things to check before doing so:

* Are you using the latest version of `bugsnag-cocoa-performance`? If not, does updating to the 
  latest version fix your issue?
* Has somebody else [already reported](https://github.com/bugsnag/bugsnag-cocoa-performance/issues?utf8=%E2%9C%93&q=is%3Aissue%20is%3Aopen) 
  your issue? Feel free to add additional context to or check-in on an existing 
  issue that matches your own.
* Is your issue caused by this module? Only things related to the 
  `bugsnag-cocoa-performance` module should be reported here. For anything else, please 
  [contact us directly](mailto:support@bugsnag.com) and we'd be happy to help 
  you out.

### Fixing issues

If you've identified a fix to a new or existing issue, we welcome contributions!
Here are some helpful suggestions on contributing that help us merge your PR 
quickly and smoothly:

* [Fork](https://help.github.com/articles/fork-a-repo) the
  [library on GitHub](https://github.com/bugsnag/bugsnag-cocoa-performance)
* Build and test your changes. We have automated tests for many scenarios but 
  its also helpful to use `npm pack` to build the module locally and install it 
  in a real app.
* Commit and push until you are happy with your contribution
* [Make a pull request](https://help.github.com/articles/using-pull-requests)
* Ensure the automated checks pass (and if it fails, please try to address the 
  cause)

### Adding features

Unfortunately we’re unable to accept PRs that add features or refactor the 
library at this time.  However, we’re very eager and welcome to hearing 
feedback about the library so please contact us directly to discuss your idea, 
or open a [feature request](https://github.com/bugsnag/bugsnag-cocoa-performance/issues/new?template=Feature_request.md) 
to help us improve the library.

Here’s a bit about our process designing and building the BugSnag libraries:

* We have an internal roadmap to plan out the features we build, and sometimes 
  we will already be planning your suggested feature!
* Our open source libraries span many languages and frameworks so we strive to 
  ensure they are idiomatic on the given platform, but also consistent in 
  terminology between platforms. That way the core concepts are familiar whether 
  you adopt BugSnag for one platform or many.
* Finally, one of our goals is to ensure our libraries work reliably, even in 
  crashy, multi-threaded environments. Oftentimes, this requires an intensive 
  engineering design and code review process that adheres to our style and 
  linting guidelines.