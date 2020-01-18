# For more information about using CMake with Android Studio, read the
# documentation: https://d.android.com/studio/projects/add-native-code.html



cmake_minimum_required(VERSION 3.4.1)


file(GLOB_RECURSE SRC src/main/jni/*.cpp src/main/cpp/*.c)
add_library( kitdemo-lib SHARED ${SRC} )

find_library( log-lib log )

target_link_libraries( kitdemo-lib ${log-lib} )