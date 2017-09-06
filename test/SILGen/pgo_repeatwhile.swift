// RUN: rm -rf %t && mkdir %t
// RUN: %target-build-swift %s -profile-generate -Xfrontend -disable-incremental-llvm-codegen -module-name pgo_repeatwhile -o %t/main
// RUN: env LLVM_PROFILE_FILE=%t/default.profraw %target-run %t/main
// RUN: %llvm-profdata merge %t/default.profraw -o %t/default.profdata
// RUN: %target-swift-frontend %s -Xllvm -sil-full-demangle -profile-use=%t/default.profdata -emit-sorted-sil -emit-sil -module-name pgo_repeatwhile -o - | %FileCheck %s --check-prefix=SIL
// RUN: %target-swift-frontend %s -Xllvm -sil-full-demangle -profile-use=%t/default.profdata -emit-ir -module-name pgo_repeatwhile -o - | %FileCheck %s --check-prefix=IR
// need to fix SIL Opt before running this:
// %target-swift-frontend %s -Xllvm -sil-full-demangle -profile-use=%t/default.profdata -O -emit-sorted-sil -emit-sil -module-name pgo_repeatwhile -o - | %FileCheck %s --check-prefix=SIL-OPT
// %target-swift-frontend %s -Xllvm -sil-full-demangle -profile-use=%t/default.profdata -O -emit-ir -module-name pgo_repeatwhile -o - | %FileCheck %s --check-prefix=IR-OPT

// REQUIRES: profile_runtime
// REQUIRES: OS=macosx

// SIL-LABEL: // pgo_repeatwhile.guessWhile
// IR-LABEL: define swiftcc i32 @_T015pgo_repeatwhile10guessWhiles5Int32VAD1x_tF
// IR-OPT-LABEL: define swiftcc i32 @_T015pgo_repeatwhile10guessWhiles5Int32VAD1x_tF

public func guessWhile(x: Int32) -> Int32 {
  // SIL: cond_br {{.*}} !true_count(176400) !false_count(420)
  // SIL: cond_br {{.*}} !true_count(420) !false_count(42)

  var ret : Int32 = 0
  var currX : Int32 = 0
  repeat {
    var currInnerX : Int32 = x*42
    repeat {
      ret += currInnerX
      currInnerX -= 1
    } while (currInnerX > 0)
    currX += 1
  } while (currX < x)
  return ret
}

func main() {
  var guesses : Int32 = 0;

  for _ in 1...42 {
    guesses += guessWhile(x: 10)
  }
}

main()

// IR: !{!"branch_weights", i32 176401, i32 421}
// IR: !{!"branch_weights", i32 421, i32 43}
// IR-OPT: !{!"branch_weights", i32 176401, i32 421}
// IR-OPT: !{!"branch_weights", i32 421, i32 43}
