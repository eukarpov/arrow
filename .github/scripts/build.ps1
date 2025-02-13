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

clang --version

cmake -G Ninja `
    -DCMAKE_C_COMPILER_ID=Clang `
    -DCMAKE_CXX_COMPILER_ID=Clang `
    -DCMAKE_C_COMPILER=clang `
    -DCMAKE_CXX_COMPILER=clang++ `
    -DCXX_COMMON_FLAGS="-target arm64-windows-msvc" `
    -DCMAKE_C_COMPILER_WORKS=TRUE `
    -DCMAKE_CXX_COMPILER_WORKS=TRUE `
    -DCMAKE_SYSTEM_NAME=Windows `
    -DCMAKE_SYSTEM_PROCESSOR=arm64 `
    -DARROW_BUILD_TESTS=OFF `
    -DARROW_PARQUET=ON `
    ../cpp

Write-Output "The first patching..."
$ninja_file =  ".\CMakeFiles\rules.ninja"
$temp_file = ".\temp"
(Get-Content $ninja_file) `
    -replace '-Wl,--out-implib,', '-Xlinker /implib:' `
    -replace '-Wl,--major-image-version[^ ]+', '' | 
Set-Content $temp_file
Move-Item $temp_file $ninja_file -Force

cmake --build .

Get-ChildItem -Recurse -File -Include CMakeCXXCompiler.cmake
Get-ChildItem boost_ep-prefix -Recurse -File -Include config.hpp

Write-Output "The second patching..."
$thrift_cmake="thrift_ep-prefix\src\thrift_ep-build\CMakeFiles\3.31.5\CMakeCXXCompiler.cmake"
(Get-Content $thrift_cmake) | Where-Object { $_ -notmatch "CMAKE_CXX_SIMULATE_ID" } | Set-Content $temp_file
Move-Item $temp_file $thrift_cmake -Force

$boost_config="boost_ep-prefix\src\boost_ep\boost\locale\config.hpp"
(Get-Content $boost_config) | Where-Object { $_ -notmatch "define BOOST_DYN_LINK" } | Set-Content $temp_file
Move-Item $temp_file $boost_config -Force

cmake --build .

Write-Output "The third patching..."
Copy-Item thrift_ep-install\lib\thrift.lib thrift_ep-install\lib\libthrift.a

cmake --build .

Get-ChildItem -Recurse -File -Include libparquet*

cd ..

ls .\build\release\
Compress-Archive -Path ".\build\release\*" -DestinationPath ".\build\apache-arrow-windows-arm64.zip" -Force

exit 0