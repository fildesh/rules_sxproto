#include <iostream>

#include <fildesh/ostream.hh>
#include <google/protobuf/text_format.h>

#include "protobuf_schemae.hh"


static
  bool
write_message_to_sxproto_ostream(
    std::ostream& out,
    const google::protobuf::Message& message)
{
  using google::protobuf::FieldDescriptor;
  using google::protobuf::Message;
  using google::protobuf::Reflection;
  using google::protobuf::TextFormat;

  const Reflection* reflection = message.GetReflection();

  std::vector<const FieldDescriptor*> fields;
  reflection->ListFields(message, &fields);

  for (const FieldDescriptor* field : fields) {
    out << '(' << field->name() << ' ';
    if (field->is_repeated()) {
      out << "(())";
      int n = reflection->FieldSize(message, field);

      if (field->type() == FieldDescriptor::TYPE_MESSAGE) {
        for (int i = 0; i < n; ++i) {
          out << "(()";
          const bool good = write_message_to_sxproto_ostream(
              out, reflection->GetRepeatedMessage(message, field, i));
          if (!good) {return false;}
          out << ')';
        }
      }
      else {
        for (int i = 0; i < n; ++i) {
          if (i > 0) {out << ' ';}
          std::string s;
          TextFormat::PrintFieldValueToString(message, field, i, &s);
          if (field->type() == FieldDescriptor::TYPE_BOOL) {
            out << '+';
          }
          out << s;
        }
      }
    }
    else {
      if (field->type() == FieldDescriptor::TYPE_MESSAGE) {
        const Message& submessage = reflection->GetMessage(message, field);
        const bool good = write_message_to_sxproto_ostream(out, submessage);
        if (!good) {return false;}
      }
      else {
        std::string s;
        TextFormat::PrintFieldValueToString(message, field, -1, &s);
        if (field->type() == FieldDescriptor::TYPE_BOOL) {
          out << '+';
        }
        out << s;
      }
    }

    out << ')';
  }
  return true;
}

static
  bool
write_message_to_sxproto_file(
    const std::string& out_filename,
    const google::protobuf::Message& message)
{
  // Open.
  fildesh::ofstream out(out_filename.c_str());
  if (!out) {
    std::cerr << "Error opening output file: " << out_filename << std::endl;
    return false;
  }
  // Encode & Write.
  return write_message_to_sxproto_ostream(out, message);
}

  int
main(int argc, char** argv)
{
  const unsigned descriptor_index_offset = 4;
  if (argc <= static_cast<int>(descriptor_index_offset)) {
    std::cerr
      << "Please provide an input, output, message name, and descriptor set file(s)."
      << std::endl;
    return 64;
  }

  std::unique_ptr<ProtobufSchemae> schemae;
  std::unique_ptr<google::protobuf::Message> message;

  schemae = ProtobufSchemae::from_descriptor_files(
      std::vector<std::string>(&argv[descriptor_index_offset], &argv[argc]));
  if (schemae) {
    // Read & Parse.
    message = schemae->new_message_from_binary_file(argv[1], argv[3]);
  }

  int exstatus = 65;
  if (message) {
    exstatus = 74;
    // Encode & Write.
    if (write_message_to_sxproto_file(argv[2], *message)) {
      exstatus = 0;
    }
  }

  google::protobuf::ShutdownProtobufLibrary();
  return exstatus;
}
