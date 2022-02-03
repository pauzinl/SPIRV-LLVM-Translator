; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_INTEL_pipes -spirv-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; RUN: llvm-spirv %t.bc --spirv-ext=+SPV_INTEL_pipes -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.bc
; RUN: llvm-dis < %t.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: Constant [[#]] [[#MemSemanticsNone:]] 0
; CHECK-SPIRV: Constant [[#]] [[#CID:]] 4
; CHECK-SPIRV: Constant [[#]] [[#MemSemanticsAcq:]] 2
; CHECK-SPIRV: Constant [[#]] [[#MemSemanticsAcqRel:]] 8
; CHECK-SPIRV: Constant [[#]] [[#MemSemanticsSeqQst:]] 10
; CHECK-SPIRV: TypePipe [[#PipeRTy:]] 0
; CHECK-SPIRV: TypePipe [[#PipeWTy:]] 1
; CHECK-SPIRV: FunctionParameter [[#PipeRTy]] [[#ReadPipeArgID:]]
; CHECK-SPIRV: ReadPipeExtINTEL [[#]] [[#]] [[#ReadPipeArgID]] [[#]] [[#CID]] [[#CID]] [[#MemSemanticsNone]]
; CHECK-SPIRV: FunctionParameter [[#PipeWTy]] [[#WritePipeArgID:]]
; CHECK-SPIRV: WritePipeExtINTEL [[#]] [[#]] [[#WritePipeArgID]] [[#]] [[#CID]] [[#CID]] [[#MemSemanticsAcq]]
; CHECK-SPIRV: Load [[#PipeRTy]] [[#PipeR:]] [[#]] [[#]] [[#]]
; CHECK-SPIRV: ReadPipeBlockingExtINTEL [[#PipeR]] [[#]] [[#CID]] [[#CID]] [[#MemSemanticsAcqRel]]
; CHECK-SPIRV: Load [[#PipeWTy]] [[#PipeW:]] [[#]] [[#]] [[#]]
; CHECK-SPIRV: WritePipeBlockingExtINTEL [[#PipeW]] [[#]] [[#CID]] [[#CID]] [[#MemSemanticsSeqQst]]

; CHECK-LLVM: %opencl.pipe_ro_t = type opaque
; CHECK-LLVM: %opencl.pipe_wo_t = type opaque

; CHECK-LLVM: call spir_func i32 @__read_pipe_3_ext(%opencl.pipe_ro_t addrspace(1)* %in_pipe, i8 addrspace(4)* %[[#]], i32 4, i32 4, i32 0)
; CHECK-LLVM: call spir_func i32 @__write_pipe_3_ext(%opencl.pipe_wo_t addrspace(1)* %out_pipe, i8 addrspace(4)* %[[#]], i32 4, i32 4, i32 2)
; CHECK-LLVM: call spir_func void @__read_pipe_3_bl_ext(%opencl.pipe_ro_t addrspace(1)* %[[#]], i8 addrspace(4)* %[[#]], i32 4, i32 4, i32 8)
; CHECK-LLVM: call spir_func void @__write_pipe_3_bl_ext(%opencl.pipe_wo_t addrspace(1)* %[[#]], i8 addrspace(4)* %[[#]], i32 4, i32 4, i32 10)

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

%opencl.pipe_ro_t = type opaque
%opencl.pipe_wo_t = type opaque

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @test_pipe_read_ext(%opencl.pipe_ro_t addrspace(1)* %in_pipe, i32 addrspace(1)* %dst) #0 {
entry:
  %call = tail call spir_func i64 @_Z13get_global_idj(i32 0)
  %sext = shl i64 %call, 32
  %idxprom = ashr exact i64 %sext, 32
  %arrayidx = getelementptr inbounds i32, i32 addrspace(1)* %dst, i64 %idxprom
  %0 = bitcast i32 addrspace(1)* %arrayidx to i8 addrspace(1)*
  %1 = addrspacecast i8 addrspace(1)* %0 to i8 addrspace(4)*
  %2 = tail call spir_func i32 @_Z24__spirv_ReadPipeExtINTELiEv8ocl_pipePiii(%opencl.pipe_ro_t addrspace(1)* %in_pipe, i8 addrspace(4)* %1, i32 4, i32 4, i32 0)
  ret void
}

; Function Attrs: convergent mustprogress nofree nounwind readnone willreturn
declare spir_func i64 @_Z13get_global_idj(i32)

declare spir_func i32 @_Z24__spirv_ReadPipeExtINTELiEv8ocl_pipePiii(%opencl.pipe_ro_t addrspace(1)*, i8 addrspace(4)*, i32, i32, i32)

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @test_pipe_write_ext(i32 addrspace(1)* %src, %opencl.pipe_wo_t addrspace(1)* %out_pipe) #0 {
entry:
  %call = tail call spir_func i64 @_Z13get_global_idj(i32 0)
  %sext = shl i64 %call, 32
  %idxprom = ashr exact i64 %sext, 32
  %arrayidx = getelementptr inbounds i32, i32 addrspace(1)* %src, i64 %idxprom
  %0 = bitcast i32 addrspace(1)* %arrayidx to i8 addrspace(1)*
  %1 = addrspacecast i8 addrspace(1)* %0 to i8 addrspace(4)*
  %2 = tail call spir_func i32 @_Z25__spirv_WritePipeExtINTELiEv8ocl_pipePiii(%opencl.pipe_wo_t addrspace(1)* %out_pipe, i8 addrspace(4)* %1, i32 4, i32 4, i32 2)
  ret void
}

declare spir_func i32 @_Z25__spirv_WritePipeExtINTELiEv8ocl_pipePiii(%opencl.pipe_wo_t addrspace(1)*, i8 addrspace(4)*, i32, i32, i32)

; Function Attrs: convergent noinline nounwind optnone
define spir_func void @test_pipe_read_blocking_ext(%opencl.pipe_ro_t addrspace(1)* %p, i32 addrspace(1)* %ptr) #0 {
entry:
  %p.addr = alloca %opencl.pipe_ro_t addrspace(1)*, align 8
  %ptr.addr = alloca i32 addrspace(1)*, align 8
  store %opencl.pipe_ro_t addrspace(1)* %p, %opencl.pipe_ro_t addrspace(1)** %p.addr, align 8
  store i32 addrspace(1)* %ptr, i32 addrspace(1)** %ptr.addr, align 8
  %0 = load %opencl.pipe_ro_t addrspace(1)*, %opencl.pipe_ro_t addrspace(1)** %p.addr, align 8
  %1 = load i32 addrspace(1)*, i32 addrspace(1)** %ptr.addr, align 8
  %2 = addrspacecast i32 addrspace(1)* %1 to i32 addrspace(4)*
  call spir_func void @_Z32__spirv_ReadPipeBlockingExtINTELIiEv8ocl_pipePiii(%opencl.pipe_ro_t addrspace(1)* %0, i32 addrspace(4)* %2, i32 4, i32 4, i32 8)
  ret void
}

declare dso_local spir_func void @_Z32__spirv_ReadPipeBlockingExtINTELIiEv8ocl_pipePiii(%opencl.pipe_ro_t addrspace(1)*, i32 addrspace(4)*, i32, i32, i32)

; Function Attrs: convergent noinline nounwind optnone
define spir_func void @test_pipe_write_blocking_ext(%opencl.pipe_wo_t addrspace(1)* %p, i32 addrspace(1)* %ptr) #0 {
entry:
  %p.addr = alloca %opencl.pipe_wo_t addrspace(1)*, align 8
  %ptr.addr = alloca i32 addrspace(1)*, align 8
  store %opencl.pipe_wo_t addrspace(1)* %p, %opencl.pipe_wo_t addrspace(1)** %p.addr, align 8
  store i32 addrspace(1)* %ptr, i32 addrspace(1)** %ptr.addr, align 8
  %0 = load %opencl.pipe_wo_t addrspace(1)*, %opencl.pipe_wo_t addrspace(1)** %p.addr, align 8
  %1 = load i32 addrspace(1)*, i32 addrspace(1)** %ptr.addr, align 8
  %2 = addrspacecast i32 addrspace(1)* %1 to i32 addrspace(4)*
  call spir_func void @_Z33__spirv_WritePipeBlockingExtINTELIKiEv8ocl_pipePiii(%opencl.pipe_wo_t addrspace(1)* %0, i32 addrspace(4)* %2, i32 4, i32 4, i32 10)
  ret void
}

declare dso_local spir_func void @_Z33__spirv_WritePipeBlockingExtINTELIKiEv8ocl_pipePiii(%opencl.pipe_wo_t addrspace(1)*, i32 addrspace(4)*, i32, i32, i32)

attributes #0 = { convergent noinline nounwind optnone "correctly-rounded-divide-sqrt-fp-math"="false" "denorms-are-zero"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

