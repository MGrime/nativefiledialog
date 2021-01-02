-- Native file dialog premake5 script
--
-- This can be ran directly, but commonly, it is only run
-- by package maintainers.
--
-- IMPORTANT NOTE: premake5 alpha 9 does not handle this script
-- properly.  Build premake5 from Github master, or, presumably,
-- use alpha 10 in the future.


newoption {
   trigger     = "linux_backend",
   value       = "B",
   description = "Choose a dialog backend for linux",
   allowed = {
      { "gtk3", "GTK 3 - link to gtk3 directly" },      
      { "zenity", "Zenity - generate dialogs on the end users machine with zenity" }
   }
}

if not _OPTIONS["linux_backend"] then
   _OPTIONS["linux_backend"] = "gtk3"
end

project "nfd"
    kind "StaticLib"
	staticruntime "On"
	
	-- these dir specifications assume the generated files have been moved
  -- into a subdirectory.  ex: $root/build/makefile
  local root_dir = path.join(path.getdirectory(_SCRIPT),"../")
  local build_dir = path.join(root_dir,"build/")
  configurations { "Release", "Debug" }

  -- Apple stopped distributing an x86 toolchain.  Xcode 11 now fails to build with an 
  -- error if the invalid architecture is present.
  --
  -- Add it back in here to build for legacy systems.
  filter "system:macosx"
    platforms {"x64"}
  filter "system:windows or system:linux"
    platforms {"x64", "x86"}
  

  objdir(path.join(build_dir, "obj/"))

  -- architecture filters
  filter "configurations:x86"
    architecture "x86"
  
  filter "configurations:x64"
    architecture "x86_64"

  -- debug/release filters
  filter "configurations:Debug"
    defines {"DEBUG"}
    symbols "On"
    targetsuffix "_d"

  filter "configurations:Release"
    defines {"NDEBUG"}
    optimize "On"


    -- common files
    files {root_dir.."src/*.h",
           root_dir.."src/include/*.h",
           root_dir.."src/nfd_common.c",
    }

    includedirs {root_dir.."src/include/"}
    targetdir(build_dir.."/lib/%{cfg.buildcfg}/%{cfg.platform}")

    warnings "extra"

    -- system build filters
    filter "system:windows"
      language "C++"
      files {root_dir.."src/nfd_win.cpp"}

    filter {"action:gmake or action:xcode4"}
      buildoptions {"-fno-exceptions"}

    filter "system:macosx"
      language "C"
      files {root_dir.."src/nfd_cocoa.m"}



    filter {"system:linux", "options:linux_backend=gtk3"}
      language "C"
      files {root_dir.."src/nfd_gtk.c"}
      buildoptions {"`pkg-config --cflags gtk+-3.0`"}
    filter {"system:linux", "options:linux_backend=zenity"}
      language "C"
      files {root_dir.."src/nfd_zenity.c"}


    -- visual studio filters
    filter "action:vs*"
      defines { "_CRT_SECURE_NO_WARNINGS" }      
