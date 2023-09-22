load("@io_bazel_rules_docker//docker/util:run.bzl", "container_run_and_extract")

# Windows path utility functions
def _double_escape(str):
    return str.replace("\\", "\\\\")

def _make_win_path(path):
    return path.replace("/", "\\")

def _make_root_win_path(path):
    if (path.startswith("/")):
        return "Z:" + _make_win_path(path)
    else:
        return "Z:\\" + _make_win_path(path)

def _make_full_win_path(path, mntpoint):
    if path.startswith("/"):
        return _make_root_win_path(mntpoint + path)
    else:
        return _make_root_win_path(mntpoint + "\\" + path)

def _rename_exn(file, exn):
    return file.split(".")[0] + "." + exn

# Image path functions
def _dotnet_framework_loc():
    return "C:\\windows\\Microsoft.NET\\Framework\\v4.0.30319"

def _win_sdk_loc():
    return "C:\\Program Files (x86)\\Windows Kits\\10\\include\\10.0.17763"

def _win_jni_hdrs_loc():
    return ["Z:\\opt\\javainclude", "Z:\\opt\\javainclude\\win32"]

# MSVC/CL.exe/LINK.exe executable invocation functions
def _win_invoke_cl():
    return ["vcwine", "cl"]

def _win_invoke_link():
    return ["vcwine", "link"]

# NOTE: ported to Dockerfile.winjdk and pulled with a container_pull
# MSVC docker image customization with JDK (windows + linux)
#def _msvc_java_layers():
#    #this rule will silently fail
#
#    if not(native.existing_rules().get("msvc-win-javaheaders-lyr")):
#        container_run_and_commit_layer(
#            name = "msvc-win-javaheaders-lyr",
#            commands = [
#                "export DEBIAN_FRONTEND=noninteractive",
#                "apt update",
#                "apt install -y openjdk-8-jdk unzip wget",
#                "mkdir /opt/msvc",
#                "cd /opt/msvc && wget https://download.java.net/openjdk/jdk8u41/ri/openjdk-8u41-b04-windows-i586-14_jan_2020.zip",
#                "cd /opt/msvc && unzip openjdk-8u41-b04-windows-i586-14_jan_2020.zip",
#                "cp -r /opt/msvc/java-se-8u41-ri/include /opt/javainclude",
#                "rm -fr /opt/msvc/java-se-8u41-ri && rm -fr /opt/msvc/openjdk-8u41-b04-windows-i586-14_jan_2020.zip"
#            ],
#            image = "@msvc//image",
#            compression = "gzip",
#        )
#    if not(native.existing_rules().get("msvc-lyr-img")):
#        container_image(
#            name = "msvc-lyr-img",
#            base = "@msvc//image",
#            layers = [":msvc-win-javaheaders-lyr"],
#            compression = "gzip",
#            experimental_tarball_format = "compressed",
#        )

def _prep_srcs(name, srcs):
    src_tarfile_name = name + "-src-tarfile"

    # I'd use pkg_tar here to do the same, but it flattens namespaces so filename collisions are possible
    #    pkg_tar(
    #        name = src_tarfile_name,
    #        srcs = jni_srcs + cpp_cli_srcs + rt_dlls,
    #    )
    # TODO python this tar thing so it's xplat
    native.genrule(
        name = src_tarfile_name,
        srcs = srcs,
        outs = [src_tarfile_name + ".tar"],
        cmd = "tar -chf $@ $(SRCS)",
    )

    return src_tarfile_name + ".tar"

# kung
def fu(x):
    return "/FU" + '\\"' + _double_escape(x) + '\\"'

def msvc_jni_cl(name, includes, jni_srcs, rt_dlls, cpp_cli_srcs, bits = 64, dotnet_dlls = [], wpf_dlls = []):
    # TODO includes, wpf_dlls, oneshot compile+link, link-only, genrule tar extraction to filegroup
    if not (bits == 32 or bits == 64):
        fail(msg = "bits must be 32 or 64, you supplied" + bits)

    src_tar_name = _prep_srcs(name + "-cl", jni_srcs + cpp_cli_srcs + includes + rt_dlls)
    src_container_name = name + "-msvccl-img"

    cpp_in_paths = [_make_full_win_path(x, "/" + native.package_name()) for x in cpp_cli_srcs]
    cpp_addnl_include_paths = [_make_full_win_path(x, "/" + native.package_name()) for x in includes]
    dotnet_dll_force_using_paths = [_dotnet_framework_loc() + "\\" + x for x in dotnet_dlls]
    dotnet_wpf_dll_force_using_paths = [_dotnet_framework_loc() + "\\WPF\\" + x for x in wpf_dlls]
    rt_dlls_paths = [_make_full_win_path(x, "/" + native.package_name()) for x in rt_dlls]

    dotnet_dll_args = [fu(x) for x in dotnet_dll_force_using_paths]
    dotnet_wpf_dll_args = [fu(x) for x in dotnet_wpf_dll_force_using_paths]
    rt_dll_args = [fu(x) for x in rt_dlls_paths]

    # NB the double escaped things here may require an additional \ at the end
    const_args = _win_invoke_cl() + [
        "/c",
        # References?
        "/AI" + '\\"' + _double_escape(_dotnet_framework_loc()) + '\\"',
        "/Zi",
        "/clr",
        "/nologo",
        "/W3",
        "/WX-",
        "/Od",
        "/Oy-",
        "/D WIN32",
        "/D _DEBUG",
        "/D _UNICODE",
        "/D UNICODE",
        "/EHa",
        "/MDd",
        "/GS",
        "/fp:precise",
        "/Zc:wchar_t",
        "/Zc:forScope",
        "/Zc:inline",
        "/I" + '\\"' + _double_escape(_make_win_path("/opt/jni")) + '\\"',
    ] + ["/I" + '\\"' + _double_escape(x) + '\\"' for x in _win_jni_hdrs_loc()]

    args = " ".join(const_args + dotnet_dll_args + dotnet_wpf_dll_args + rt_dll_args)
    src_args = " ".join(['\\"' + _double_escape(x) + '\\"' for x in cpp_in_paths])

    rt_name = name + "-cl"

    msvcarch = ""
    if bits == 64:
        msvcarch = "64"
    if bits == 32:
        msvcarch = "32"

    # this part is super cursed
    # if you ever need to debug this, find . -name "extract.sh.tpl and edit that directly to allow for debug statemetns"
    container_run_and_extract(
        name = rt_name,
        # undocumented, but the files end up next to the script for docker invocation
        extra_deps = [src_tar_name],
        # so we can find the source tar file from extra_deps and mount it in the docker container
        docker_run_flags = ["-v $(find . -name '{}' | head -1 | xargs realpath):{}".format(src_tar_name, "/src.tar")],
        commands = [
            "cd / && tar -xvf /src.tar",
            "mkdir /opt/jni",
            "find /{} -name \\\"*.java\\\" | xargs javac -h /opt/jni".format(native.package_name()),
            "ls /opt/jni",
            "mkdir /opt/out",
            "cd /opt/out",
            "export MSVCARCH={}".format(msvcarch),
            args + " " + src_args,
            "cd /opt",
            "tar -chf out.tar out/*",
        ],
        extract_file = "/opt/out.tar",
        image = "@msvc_winjdk//image",
    )

    # required prefixing to avoid name collision of generated objs
    outobjs = [name + "/" + _rename_exn(x.split("/")[-1], "obj") for x in cpp_cli_srcs]
    native.genrule(
        name = name + "-cl-untar",
        srcs = [rt_name + "/opt/out.tar"],
        outs = outobjs,
        cmd = """tar -xf $(location {rt_tar}) &&
        mv out/* $(@D)/{name}
        """.format(
            rt_tar = rt_name + "/opt/out.tar",
            name = name,
        ),
    )
    native.filegroup(
        name = name + "-out",
        srcs = outobjs,
    )

def msvc_jni_link(name, srcs, bits = 64):
    if not (bits == 32 or bits == 64):
        fail(msg = "bits must be 32 or 64, you supplied" + bits)

    #_msvc_java_layers()
    src_container_name = name + "-msvclink-img"
    src_tar_name = _prep_srcs(name + "-link", srcs)

    machine = "/MACHINE:"
    msvcarch = ""
    if bits == 64:
        machine = machine + "X64"
        msvcarch = "64"
    if bits == 32:
        machine = machine + "X86"
        msvcarch = "32"

    # this part is super cursed
    # if you ever need to debug this, find . -name "extract.sh.tpl and edit that directly to allow for debug statemetns"
    container_run_and_extract(
        name = name + "-dll",
        # undocumented, but the files end up next to the script for docker invocation
        extra_deps = [src_tar_name],
        # so we can find the source tar file from extra_deps and mount it in the docker container
        docker_run_flags = ["-v $(find . -name '{}' | head -1 | xargs realpath):{}".format(src_tar_name, "/src.tar")],
        # escaping hell
        commands = [
            "cd / && tar -xf /src.tar",
            "export MSVCARCH={}".format(msvcarch),
            """tar -tf /src.tar | awk '{print \\"Z:\\" \\$1}' | tr '\n' ' ' >> /tmp/in.txt""",
            "cat /tmp/in.txt",
            "cat /tmp/in.txt | xargs " + " ".join(_win_invoke_link() + [
                "/OUT:\"{name}.dll\" ".format(name = name),
                machine,
                "/DLL",
            ]),
            "ls -la",
            "echo \"{}\"".format(name),
        ],
        extract_file = "/{name}.dll".format(name = name),
        image = "@msvc_winjdk//image",
    )

def msvc_jni(name, includes, jni_srcs, rt_dlls, cpp_cli_srcs, bits = 64, dotnet_dlls = [], wpf_dlls = []):
    msvc_jni_cl(name, includes, jni_srcs, rt_dlls, cpp_cli_srcs, bits, dotnet_dlls, wpf_dlls)
    msvc_jni_link(name, [":" + name + "-out"], bits)
