module;

export module simple;

int AddInternal(int add, int b) {
  return add * b;
}

export int Add(int a, int b) {
  return a + b + AddInternal(a, b);
}

export struct Quaternion {
  double a_, b_, c_, d_;
};
