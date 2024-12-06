param (
    [switch]$clean
)

Write-Output "Build arm64:windows arrow"

if ($clean -and (Test-Path .\build)) {
    Write-Output "Clean build"
    rm -r build -ErrorAction SilentlyContinue | Out-Null
}

mkdir build -ErrorAction SilentlyContinue | Out-Null
cd build

cmake -G Ninja `
    -DCMAKE_C_COMPILER_ID=Clang `
    -DCMAKE_CXX_COMPILER_ID=Clang `
    -DCMAKE_C_COMPILER=clang `
    -DCMAKE_CXX_COMPILER=clang++ `
    -DCMAKE_C_COMPILER_WORKS=TRUE `
    -DCMAKE_CXX_COMPILER_WORKS=TRUE `
    ../cpp

$ninja_file =  ".\CMakeFiles\rules.ninja"
(Get-Content $ninja_file) `
    -replace '-Wl,--out-implib,', '-Xlinker /implib:' `
    -replace '-Wl,--major-image-version[^ ]+', '' | 
Set-Content $ninja_file

cmake --build .
cd ..

ls .\build\release\