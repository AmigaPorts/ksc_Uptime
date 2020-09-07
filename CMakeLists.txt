cmake_minimum_required(VERSION 2.8.5)

project(ksc_Uptime ASM C)

if (AMIGAOS3)
	enable_language(ASM_VASM)
	set(
		SOURCES
		uptime.asm
	)

	set(
		HEADERS
		""
	)

	set(CMAKE_EXE_LINKER_FLAGS "" CACHE PATH "LINKER FLAGS" FORCE)

	include_directories(
			${CMAKE_CURRENT_SOURCE_DIR}
	)

	set(${PROJECT_NAME}_INCLUDE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PARENT_SCOPE)
	add_executable(${PROJECT_NAME} ${SOURCES} ${HEADERS})
else()
	message(FATAL_ERROR "This application can only be built for Amiga")
endif()
