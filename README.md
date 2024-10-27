# CMake-based PostgreSQL Extensions

Template project for building CMake-based PostgreSQL extensions.

## Dependencies

Use C++ Modules to build the extensions. so you need to have:
- CMake version 3.28 or later
- GCC version 14 or clang-17 later.
- PostgreSQL server version 16 or later. (meson build)

You can install these dependencies on Ubuntu 24.04 in [build.yml](.github/workflows/build.yml)

## Building for Development

Make sure Dependencies and do the following steps:

```bash
cmake --preset ClangDebug
cmake --build build/ClangDebug --target install
cmake --build build/ClangDebug --target test
```

If you want to run with coverage, you can use the following command:

```bash
cmake --preset Coverage
cmake --build build/Coverage --target install
cmake --build build/Coverage --target test

grcov . -b build/Coverage -s . -o coverage -t html --branch --ignore-not-existing
```

# TODO

* memory check  
* cpp source code test  
* error handling  
* ...  


