# jsonapi-model

<!-- [![Gem Version](https://badge.fury.io/rb/jsonapi-model.svg)](https://badge.fury.io/rb/jsonapi-model) -->
<!-- [![Build Status](https://app.travis-ci.com/rdnewman/loba.svg?branch=main)](https://app.travis-ci.com/rdnewman/loba)
[![Code Climate](https://codeclimate.com/github/rdnewman/loba/badges/gpa.svg)](https://codeclimate.com/github/rdnewman/loba)
[![Test Coverage](https://codeclimate.com/github/rdnewman/loba/badges/coverage.svg)](https://codeclimate.com/github/rdnewman/loba/coverage)
[![Inline docs](http://inch-ci.org/github/rdnewman/loba.svg?branch=master)](http://inch-ci.org/github/rdnewman/loba)
[![security](https://hakiri.io/github/rdnewman/loba/main.svg)](https://hakiri.io/github/rdnewman/loba/main) -->

ActiveModel resource model classes using JSONAPI endpoints.

## Overview

This gem helps support writing Rails applications where remote JSONAPI endpoints may
be involved.

Support for writing Rails apps to provide JSONAPI backends for use by other apps is 
plentiful, but writing a Rails app to use another (remote) JSONAPI-based API generally has 
involved manually deserializing the JSONAPI content from the remote API and then perhaps 
building an ActiveModel or facade against it.

While this is not too onerous when the remote service provides a ready connector or facade
for working with their API, those primarily only appear for JavaScript; Ruby support is
often lacking.

This gem is currently a work-in-progress.  As of this writing, a first usable version is
nearly ready for release, but even so it will need use by others to ensure it meets more
general needs in the wild.

## Usage

TBD.
