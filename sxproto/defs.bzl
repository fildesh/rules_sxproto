load("@fildesh//tool/bazel:spawn_test.bzl", _spawn_test = "spawn_test")
load("@rules_proto//proto:defs.bzl", _proto_descriptor_set = "proto_descriptor_set")

# Attributes common to protobuf transcode rules.
_PROTOBUF_TRANSCODE_RULE_ATTRS = {
    "src": attr.label(
        mandatory = True,
        allow_single_file = True,
        doc = "The file to decode.",
    ),
    "out": attr.output(
        mandatory = False,
        doc = "The file to encode.",
    ),
    "proto_deps": attr.label_list(
        mandatory = True,
        doc = "Names of proto_data that have the info needed to compile a message.",
    ),
    "proto_message": attr.string(
        mandatory = True,
        doc = "Type of message that the input file represents.",
    ),
}


def _out_or_suffixed_file(ctx, suffix):
  out_file = ctx.outputs.out
  if not out_file:
    out_file = ctx.actions.declare_file(ctx.label.name + suffix)
  return out_file


def _descriptor_set_depset(ctx):
  transitive_descriptor_sets = [
      dep[ProtoInfo].transitive_descriptor_sets
      for dep in ctx.attr.proto_deps
  ]
  return depset(ctx.files.proto_deps,
                transitive=transitive_descriptor_sets)


def _run_protobuf_transcode(
    ctx, executable_file,
    in_file, out_file,
    proto_message, descriptor_set_depset):
  args = ctx.actions.args()
  args.add(in_file)
  args.add(out_file)
  args.add(proto_message)
  args.add_all(descriptor_set_depset)
  ctx.actions.run(
      executable = executable_file,
      arguments = [args],
      inputs = depset([in_file], transitive=[descriptor_set_depset]),
      outputs = [out_file],
  )
  return [out_file]


def _protobuf_transcode_impl(ctx):
  primary_out_file = _out_or_suffixed_file(ctx, ctx.attr._default_output_suffix)
  outfiles = _run_protobuf_transcode(
      ctx,
      ctx.executable._transcode_protobuf,
      ctx.file.src,
      primary_out_file,
      ctx.attr.proto_message,
      _descriptor_set_depset(ctx),
  )
  return DefaultInfo(
      files = depset([primary_out_file]),
      runfiles = ctx.runfiles(files = outfiles),
  )

data_sxproto = rule(
    implementation = _protobuf_transcode_impl,
    attrs = dict(_PROTOBUF_TRANSCODE_RULE_ATTRS, **{
        "_default_output_suffix": attr.string(
            mandatory = False,
            default = ".sxpb",
        ),
        "_transcode_protobuf": attr.label(
            default = Label("//tool:binaryproto2sxproto"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    }),
)

textproto_data = rule(
    implementation = _protobuf_transcode_impl,
    attrs = dict(_PROTOBUF_TRANSCODE_RULE_ATTRS, **{
        "_default_output_suffix": attr.string(
            mandatory = False,
            default = ".binpb",
        ),
        "_transcode_protobuf": attr.label(
            default = Label("//tool:textproto2binaryproto"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    }),
)

data_textproto = rule(
    implementation = _protobuf_transcode_impl,
    attrs = dict(_PROTOBUF_TRANSCODE_RULE_ATTRS, **{
        "_default_output_suffix": attr.string(
            mandatory = False,
            default = ".txtpb",
        ),
        "_transcode_protobuf": attr.label(
            default = Label("//tool:binaryproto2textproto"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    }),
)

json_data = rule(
    implementation = _protobuf_transcode_impl,
    attrs = dict(_PROTOBUF_TRANSCODE_RULE_ATTRS, **{
        "_default_output_suffix": attr.string(
            mandatory = False,
            default = ".binpb",
        ),
        "_transcode_protobuf": attr.label(
            default = Label("//tool:json2binaryproto"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    }),
)

data_json = rule(
    implementation = _protobuf_transcode_impl,
    attrs = dict(_PROTOBUF_TRANSCODE_RULE_ATTRS, **{
        "_default_output_suffix": attr.string(
            mandatory = False,
            default = ".json",
        ),
        "_transcode_protobuf": attr.label(
            default = Label("//tool:binaryproto2json"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    }),
)

data_json_camelcase = rule(
    implementation = _protobuf_transcode_impl,
    attrs = dict(_PROTOBUF_TRANSCODE_RULE_ATTRS, **{
        "_default_output_suffix": attr.string(
            mandatory = False,
            default = ".json",
        ),
        "_transcode_protobuf": attr.label(
            default = Label("//tool:binaryproto2json_camelcase"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    }),
)


def _run_sxpb2json(ctx, sxpb_file, json_file):
  """Translate .sxpb file to .json file."""
  args = ctx.actions.args()
  args.add_joined(["stdin=open_readonly", sxpb_file], join_with = ":")
  args.add_joined(["stdout=open_writeonly", json_file], join_with = ":")
  args.add("--")
  args.add(ctx.executable._sxpb2json)
  ctx.actions.run(
      executable = ctx.executable._fildespawn,
      arguments = [args],
      inputs = [sxpb_file],
      outputs = [json_file],
      tools = [ctx.executable._sxpb2json],
  )
  return [json_file]

def _run_sxpb2txtpb(ctx, sxproto_file, textproto_file):
  """Translate .sxproto file to .txtpb file."""
  args = ctx.actions.args()
  args.add_joined(["stdin=open_readonly", sxproto_file], join_with = ":")
  args.add_joined(["stdout=open_writeonly", textproto_file], join_with = ":")
  args.add("--")
  args.add(ctx.executable._sxpb2txtpb)
  ctx.actions.run(
      executable = ctx.executable._fildespawn,
      arguments = [args],
      inputs = [sxproto_file],
      outputs = [textproto_file],
      tools = [ctx.executable._sxpb2txtpb],
  )
  return [textproto_file]

def _run_sxpb2yaml(ctx, sxpb_file, yaml_file):
  """Translate .sxpb file to .json file."""
  args = ctx.actions.args()
  args.add_joined(["stdin=open_readonly", sxpb_file], join_with = ":")
  args.add_joined(["stdout=open_writeonly", yaml_file], join_with = ":")
  args.add("--")
  args.add(ctx.executable._sxpb2yaml)
  ctx.actions.run(
      executable = ctx.executable._fildespawn,
      arguments = [args],
      inputs = [sxpb_file],
      outputs = [yaml_file],
      tools = [ctx.executable._sxpb2yaml],
  )
  return [yaml_file]


def _sxproto_data_impl(ctx):
  descriptor_set_depset = _descriptor_set_depset(ctx)
  binaryproto_file = _out_or_suffixed_file(ctx, ctx.attr._default_output_suffix)
  outfiles = [binaryproto_file]

  textproto_file = None
  if ctx.outputs.out_textproto:
    outfiles += _run_sxpb2txtpb(
        ctx, ctx.file.src, ctx.outputs.out_textproto)
    _run_protobuf_transcode(
        ctx, ctx.executable._textproto2binaryproto,
        ctx.outputs.out_textproto, binaryproto_file,
        ctx.attr.proto_message, descriptor_set_depset)
  else:
    _run_protobuf_transcode(
        ctx, ctx.executable._sxproto2binaryproto,
        ctx.file.src, binaryproto_file,
        ctx.attr.proto_message, descriptor_set_depset)

  if ctx.outputs.out_json:
    outfiles += _run_sxpb2json(
        ctx, ctx.file.src, ctx.outputs.out_json)

  if ctx.outputs.out_json_camelcase:
    outfiles += _run_protobuf_transcode(
        ctx, ctx.executable._binaryproto2json_camelcase,
        binaryproto_file, ctx.outputs.out_json_camelcase,
        ctx.attr.proto_message, descriptor_set_depset)

  if ctx.outputs.out_yaml:
    outfiles += _run_sxpb2yaml(
        ctx, ctx.file.src, ctx.outputs.out_yaml)

  return DefaultInfo(
      files = depset([binaryproto_file]),
      runfiles = ctx.runfiles(files = outfiles),
  )

sxproto_data = rule(
    implementation = _sxproto_data_impl,
    attrs = dict(_PROTOBUF_TRANSCODE_RULE_ATTRS, **{
        "_default_output_suffix": attr.string(
            mandatory = False,
            default = ".binpb",
        ),
        "out_textproto": attr.output(
            mandatory = False,
            doc = "The .txtpb file to write.",
        ),
        "out_json": attr.output(
            mandatory = False,
            doc = "The .json file to write.",
        ),
        "out_json_camelcase": attr.output(
            mandatory = False,
            doc = "The .json file to write with camelCase fields.",
        ),
        "out_yaml": attr.output(
            mandatory = False,
            doc = "The .yaml file to write.",
        ),
        "_fildespawn": attr.label(
            default = Label("@fildesh//tool:fildespawn"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_sxproto2binaryproto": attr.label(
            default = Label("//tool:sxproto2binaryproto"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_sxpb2json": attr.label(
            default = Label("//tool:sxpb2json"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_sxpb2txtpb": attr.label(
            default = Label("//tool:sxpb2txtpb"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_sxpb2yaml": attr.label(
            default = Label("//tool:sxpb2yaml"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_textproto2binaryproto": attr.label(
            default = Label("//tool:textproto2binaryproto"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_binaryproto2json": attr.label(
            default = Label("//tool:binaryproto2json"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_binaryproto2json_camelcase": attr.label(
            default = Label("//tool:binaryproto2json_camelcase"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    }),
)


def protobuf_equality_test(
    name,
    srcs,
    proto_message,
    proto_deps,
    expect_failure = False):

  srcs_fail_text = (
      "The srcs arg must be a list of exactly 2 protobuf data files " +
      "formatted as any combination of: sxpb, txtpb, json, or binpb.")
  if type(srcs) != type([]) or len(srcs) != 2:
    fail(srcs_fail_text)

  descriptor_dep = name + "_descriptor_set"
  _proto_descriptor_set(
      name = descriptor_dep,
      deps = proto_deps,
      testonly = 1,
  )
  _spawn_test(
      name = name,
      binary = "@rules_sxproto//tool:diffprotobuf",
      args = [
          "$(location " + srcs[0] + ")",
          "$(location " + srcs[1] + ")",
          proto_message,
          "$(location " + descriptor_dep + ")",
      ],
      data = srcs + [descriptor_dep],
      expect_failure = expect_failure,
  )
