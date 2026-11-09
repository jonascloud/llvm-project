// RUN: mlir-opt %s --convert-vector-to-llvm | FileCheck %s --check-prefixes=CHECK,ABI
// RUN: mlir-opt %s --convert-vector-to-llvm='use-vector-alignment=1' | FileCheck %s --check-prefixes=CHECK,VECTOR

// The default LLVM data layout gives i64 ABI alignment 4 and preferred alignment
// 8. Without an explicit guarantee, a vector access must use the element's ABI
// alignment, not its preferred alignment or the vector type's alignment.

// CHECK-LABEL: func @element_alignment(
// ABI: llvm.load {{.*}} <alignment = 4> : !llvm.ptr -> vector<2xi64>
// ABI: llvm.store {{.*}} <alignment = 4> : vector<2xi64>, !llvm.ptr
// VECTOR: llvm.load {{.*}} <alignment = 16> : !llvm.ptr -> vector<2xi64>
// VECTOR: llvm.store {{.*}} <alignment = 16> : vector<2xi64>, !llvm.ptr
func.func @element_alignment(%base: memref<?xi64>, %i: index) -> vector<2xi64> {
  %value = vector.load %base[%i] : memref<?xi64>, vector<2xi64>
  vector.store %value, %base[%i] : memref<?xi64>, vector<2xi64>
  return %value : vector<2xi64>
}

// Explicit alignment takes precedence even when weaker than element ABI
// alignment or stronger than the preferred vector alignment.

// CHECK-LABEL: func @explicit_weak_alignment(
// CHECK: llvm.load {{.*}} <alignment = 1> : !llvm.ptr -> vector<2xi64>
// CHECK: llvm.store {{.*}} <alignment = 1> : vector<2xi64>, !llvm.ptr
func.func @explicit_weak_alignment(%base: memref<?xi64>, %i: index) -> vector<2xi64> {
  %value = vector.load %base[%i] alignment = 1 : memref<?xi64>, vector<2xi64>
  vector.store %value, %base[%i] alignment = 1 : memref<?xi64>, vector<2xi64>
  return %value : vector<2xi64>
}

// CHECK-LABEL: func @explicit_strong_alignment(
// CHECK: llvm.load {{.*}} <alignment = 64> : !llvm.ptr -> vector<2xi64>
// CHECK: llvm.store {{.*}} <alignment = 64> : vector<2xi64>, !llvm.ptr
func.func @explicit_strong_alignment(%base: memref<?xi64>, %i: index) -> vector<2xi64> {
  %value = vector.load %base[%i] alignment = 64 : memref<?xi64>, vector<2xi64>
  vector.store %value, %base[%i] alignment = 64 : memref<?xi64>, vector<2xi64>
  return %value : vector<2xi64>
}
