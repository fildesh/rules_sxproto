#include "protobuf_transcode.hh"

#include <fildesh/ostream.hh>
#include <fildesh/string.hh>
#include <fildesh/sxproto.h>
#include <google/protobuf/text_format.h>
#include <google/protobuf/util/json_util.h>

#include "protobuf_schemae.hh"

using google::protobuf::Message;


static
  std::unique_ptr<Message>
new_message_from_txtpb_content(
    const std::string& in_content,
    const std::string& message_name,
    ProtobufSchemae& schemae)
{
  using google::protobuf::TextFormat;
  std::unique_ptr<Message> message = schemae.new_message(message_name);
  if (!message) {
    std::cerr << "Cannot find message type: " << message_name << std::endl;
    return nullptr;
  }

  TextFormat::Parser txtpb_parser;
  txtpb_parser.AllowFieldNumber(true);
  if (!txtpb_parser.ParseFromString(in_content, message.get())) {
    std::cerr << "Error parsing txtpb." << std::endl;
    return nullptr;
  }
  return message;
}

static
  std::unique_ptr<Message>
new_message_from_json_content(
    const std::string& in_content,
    const std::string& message_name,
    ProtobufSchemae& schemae)
{
  using google::protobuf::util::JsonStringToMessage;
  std::unique_ptr<Message> message = schemae.new_message(message_name);
  if (!message) {
    std::cerr << "Cannot find message type: " << message_name << std::endl;
    return nullptr;
  }

  auto status = JsonStringToMessage(
      in_content, message.get());
  if (!status.ok()) {
    std::cerr << "Error parsing json." << std::endl;
    return nullptr;
  }
  return message;
}

  std::unique_ptr<Message>
new_message_from_sxproto_file(
    const std::string& in_filename,
    const std::string& message_name,
    ProtobufSchemae& schemae)
{
  // Open.
  FildeshX* in = open_FildeshXF(in_filename.c_str());
  if (!in) {
    std::cerr << "Cannot open input file: " << in_filename << std::endl;
    return nullptr;
  }

  // Transcode to temporary txtpb string.
  fildesh::ofstream err_out("/dev/stderr");
  FildeshSxpb* sxpb = slurp_sxpb_close_FildeshX(in, NULL, err_out.c_struct());
  if (!sxpb) {return nullptr;}
  fildesh::ostringstream oss;
  print_txtpb_FildeshO(oss.c_struct(), sxpb);
  close_FildeshSxpb(sxpb);

  // Parse.
  return new_message_from_txtpb_content(oss.str(), message_name, schemae);
}

  std::unique_ptr<Message>
new_message_from_textproto_file(
    const std::string& in_filename,
    const std::string& message_name,
    ProtobufSchemae& schemae)
{
  // Read.
  std::string in_content;
  if (!fildesh::slurp_file_to_string(in_content, in_filename.c_str())) {
    std::cerr << "Cannot open input file: " << in_filename << std::endl;
    return nullptr;
  }

  // Parse.
  return new_message_from_txtpb_content(in_content, message_name, schemae);
}

  std::unique_ptr<Message>
new_message_from_json_file(
    const std::string& in_filename,
    const std::string& message_name,
    ProtobufSchemae& schemae)
{
  // Read.
  std::string in_content;
  if (!fildesh::slurp_file_to_string(in_content, in_filename.c_str())) {
    std::cerr << "Cannot open input file: " << in_filename << std::endl;
    return nullptr;
  }

  // Parse.
  return new_message_from_json_content(in_content, message_name, schemae);
}

  bool
write_message_to_json_file(
    const std::string& out_filename,
    const google::protobuf::Message& message,
    bool camelcase)
{
  using google::protobuf::util::JsonPrintOptions;
  using google::protobuf::util::MessageToJsonString;
  // Encode.
  std::string out_content;
  JsonPrintOptions json_options;
  json_options.preserve_proto_field_names = !camelcase;
  auto status = MessageToJsonString(
      message, &out_content, json_options);
  if (!status.ok()) {
    std::cerr << "Error encoding json." << std::endl;
    return false;
  }

  // Write.
  FildeshO* out = open_FildeshOF(out_filename.c_str());
  if (!out) {
    std::cerr << "Error opening output file: " << out_filename << std::endl;
    return false;
  }
  put_bytestring_FildeshO(
      out,
      (const unsigned char*)out_content.data(),
      out_content.size());
  close_FildeshO(out);
  return true;
}

  bool
write_message_to_json_camelcase_file(
    const std::string& out_filename,
    const google::protobuf::Message& message)
{
  return write_message_to_json_file(out_filename, message, /*camelcase=*/true);
}
