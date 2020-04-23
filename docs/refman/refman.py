import collections
import enum
import glob
import re
import sys

import mako.template
import mako.lookup


################################################################################
# File to Docstring Comments Parser
################################################################################


class FileParserState(enum.Enum):
    SEARCH = 1
    COMMENT = 2


def parse_file(filename):
    state = FileParserState.SEARCH

    comment = []
    comments = []

    with open(filename) as f:
        for line in f:
            line = line.strip()

            if state == FileParserState.SEARCH:
                if line == "---":
                    state = FileParserState.COMMENT
            elif state == FileParserState.COMMENT:
                match = re.match(r'\-\-[ ]?', line)
                if match:
                    comment.append(line[match.end():])
                else:
                    if comment:
                        comments.append(comment)
                        comment = []
                    state = FileParserState.SEARCH

    return comments


################################################################################
# Docstring Comments to Docstrings Parser
################################################################################


class DocstringParserState(enum.Enum):
    DESCRIPTION = 1
    TAG = 2


Docstring = collections.namedtuple('Docstring', ['description', 'tags'])


class DocstringTags:
    def __init__(self, tags):
        self._tags = tags

    def lookup(self, key):
        for (k, v) in self._tags:
            if k == key:
                return v
        raise KeyError("Unknown key \"{}\" in tags.".format(key))

    def lookup_optional(self, key):
        try:
            return self.lookup(key)
        except KeyError:
            return None

    def lookup_multiple(self, keys):
        return [(k, v) for (k, v) in self._tags if any([k.startswith(key) for key in keys])]

    def keys(self):
        return [re.match(r'([a-z]+)', k).group(1) for (k, v) in self._tags]

    def has(self, key):
        return key in self.keys()

    def __str__(self):
        return str(self._tags)

    def __repr__(self):
        return repr(self._tags)


def parse_comment(comment):
    state = DocstringParserState.DESCRIPTION
    tag = None
    tag_lines = []

    description = []
    tags = []

    for line in comment:
        is_tag = re.match(r'@[a-z]+.*$', line)

        if state == DocstringParserState.DESCRIPTION:
            # If this is a tag, stop collecting description
            if is_tag:
                state = DocstringParserState.TAG
            else:
                description.append(line)

        if state == DocstringParserState.TAG:
            # Add assembled tag to tags
            if tag and is_tag:
                tags.append((tag, tag_lines))
                tag, tag_lines = None, []

            # Process new tag
            if is_tag:
                tag, value = re.match(r'@([^\s]+)[\s]*(.*)', line).groups()
                if value:
                    tag_lines.append(value)
            else:
                tag_lines.append(line)

    # Add final assembled tag to tags
    if tag:
        tags.append((tag, tag_lines))

    # Trim trailing newlines in description
    if description and description[-1] == "":
        description.pop()

    # Trim trailing newlines in tag lines
    for (tag, lines) in tags:
        if lines and lines[-1] == "":
            lines.pop()

    # Join description lines
    description = "\n".join(description)

    # Join tag lines
    tags = [(tag, "\n".join(lines)) for (tag, lines) in tags]

    return Docstring(description, DocstringTags(tags))


def parse_comments(comments):
    docstrings = []

    for comment in comments:
        docstrings.append(parse_comment(comment))

    return docstrings


################################################################################
# Docstrings to Docs Decoder
################################################################################

# Assorted leaf elements

ParameterDoc = collections.namedtuple('ParameterDoc', ['name', 'type', 'default', 'description'])

ReturnDoc = collections.namedtuple('ReturnDoc', ['type', 'description'])

PortDoc = collections.namedtuple('PortDoc', ['name', 'type'])

FieldDoc = collections.namedtuple('FieldDoc', ['name', 'type', 'description'])

# Mid-level elements

SignatureDoc = collections.namedtuple('SignatureDoc', ['inputs', 'outputs'])

TableDoc = collections.namedtuple('TableDoc', ['name', 'description', 'children'])

FunctionDoc = collections.namedtuple('FunctionDoc', ['name', 'description', 'parameters', 'returns', 'raises', 'usage', 'static'])

PropertyDoc = collections.namedtuple('PropertyDoc', ['name', 'description', 'returns', 'raises', 'usage', 'static'])

# High-level elements

BlockDoc = collections.namedtuple('BlockDoc', ['name', 'description', 'category', 'parameters', 'signatures', 'usage', 'children'])

ModuleDoc = collections.namedtuple('ModuleDoc', ['name', 'description', 'children'])

ClassDoc = collections.namedtuple('ClassDoc', ['name', 'description', 'parameters', 'usage', 'children'])

DatatypeDoc = collections.namedtuple('DatatypeDoc', ['name', 'description', 'parameters', 'children'])


def decode_tag_parameters(tags):
    parameters = []

    # @tparam[opt=<default>] <type> <name> <description>
    # @param <name> <description>
    for (k, v) in tags:
        if k.startswith("tparam"):
            default = re.match(r'tparam\[opt=(.*)\]', k).group(1) if "opt=" in k else None
            type, name, description = re.match(r'([^\s]+) ([^\s]+) (.*)', v, re.MULTILINE | re.DOTALL).groups()
            parameters.append(ParameterDoc(name=name, type=type, default=default, description=description))
        elif k.startswith("param"):
            name, description = re.match(r'([^\s]+) (.*)', v, re.MULTILINE | re.DOTALL).groups()
            parameters.append(ParameterDoc(name=name, type=None, default=None, description=description))
        else:
            raise ValueError("Unknown parameter tag type \"{}\".".format(k))

    return parameters


def decode_tag_returns(tags):
    returns = []

    # @treturn <type> <description>
    # @return <description>
    for (k, v) in tags:
        if k == "treturn":
            type, description = re.match(r'([^\s]+) (.*)', v, re.MULTILINE | re.DOTALL).groups()
            returns.append(ReturnDoc(type=type, description=description))
        elif k == "return":
            description = v
            returns.append(ReturnDoc(type=None, description=description))
        else:
            raise ValueError("Unknown return tag type \"{}\".".format(k))

    return returns


def decode_tag_signatures(tags):
    signatures = []

    # @signature [<name>:<type>]... > [<name>:<type>]...
    for (k, v) in tags:
        if ">" not in v:
            raise ValueError("Invalid signature value \"{}\".".format(v))

        inputs, outputs = v.split(">")
        inputs, outputs = inputs.strip(), outputs.strip()

        input_ports, output_ports = [], []

        if inputs:
            for input in inputs.split(", "):
                if input == "...":
                    input_ports.append(PortDoc(name=input, type=None))
                else:
                    name, type = input.split(":")
                    input_ports.append(PortDoc(name=name, type=type))

        if outputs:
            for output in outputs.split(", "):
                if output == "...":
                    output_ports.append(PortDoc(name=output, type=None))
                else:
                    name, type = output.split(":")
                    output_ports.append(PortDoc(name=name, type=type))

        signatures.append(SignatureDoc(inputs=input_ports, outputs=output_ports))

    return signatures


def decode_tag_fields(tags):
    fields = []

    # @tfield <type> <name> <description>
    for (k, v) in tags:
        type, name, description = re.match(r'([^\s]+) ([^\s]+) (.*)', v, re.MULTILINE | re.DOTALL).groups()
        fields.append(FieldDoc(name=name, type=type, description=description))

    return fields


def decode_function_name(name):
    # <class>.<static function>
    # <class>:<method>
    # <module function>
    if "." in name:
        cls, static = name.split(".")[0], True
    elif ":" in name:
        cls, static = name.split(":")[0], False
    else:
        cls, static = None, True

    return (name, cls, static)


def decode_docstring_block(docstring):
    name = docstring.tags.lookup("block")
    description = docstring.description
    category = docstring.tags.lookup("category")
    parameters = decode_tag_parameters(docstring.tags.lookup_multiple(("tparam", "param")))
    signatures = decode_tag_signatures(docstring.tags.lookup_multiple(("signature",)))
    usage = docstring.tags.lookup("usage")

    return BlockDoc(name=name, description=description, category=category, parameters=parameters, signatures=signatures, usage=usage, children=[])


def decode_docstring_class(docstring):
    name = docstring.tags.lookup("class")
    description = docstring.description
    parameters = decode_tag_parameters(docstring.tags.lookup_multiple(("tparam", "param")))
    usage = docstring.tags.lookup_optional("usage")

    return ClassDoc(name=name, description=description, parameters=parameters, usage=usage, children=[])


def decode_docstring_datatype(docstring):
    name = docstring.tags.lookup("datatype")
    description = docstring.description
    parameters = decode_tag_parameters(docstring.tags.lookup_multiple(("tparam", "param")))

    return DatatypeDoc(name=name, description=description, parameters=parameters, children=[])


def decode_docstring_module(docstring):
    name = docstring.tags.lookup("module")
    description = docstring.description
    children = decode_tag_fields(docstring.tags.lookup_multiple(("tfield",)))

    return ModuleDoc(name=name, description=description, children=children)


def decode_docstring_function(docstring):
    name, cls, static = decode_function_name(docstring.tags.lookup("function"))
    description = docstring.description
    parameters = decode_tag_parameters(docstring.tags.lookup_multiple(("tparam", "param")))
    returns = decode_tag_returns(docstring.tags.lookup_multiple(("treturn", "return")))
    raises = [v for (_, v) in docstring.tags.lookup_multiple(("raise",))]
    usage = docstring.tags.lookup_optional("usage")
    static = static

    return FunctionDoc(name=name, description=description, parameters=parameters, returns=returns, raises=raises, usage=usage, static=static), cls


def decode_docstring_property(docstring):
    name, cls, static = decode_function_name(docstring.tags.lookup("property"))
    description = docstring.description
    returns = decode_tag_returns(docstring.tags.lookup_multiple(("treturn", "return")))
    raises = [v for (_, v) in docstring.tags.lookup_multiple(("raise",))]
    usage = docstring.tags.lookup_optional("usage")

    return PropertyDoc(name=name, description=description, returns=returns, raises=raises, usage=usage, static=static), cls


def decode_docstring_table(docstring):
    name = docstring.tags.lookup("table")
    description = docstring.description
    children = decode_tag_fields(docstring.tags.lookup_multiple(("tfield",)))

    return TableDoc(name=name, description=description, children=children)


def decode_docstrings(docstrings):
    docs = []
    namespace = None

    for docstring in docstrings:
        tag_keys = docstring.tags.keys()

        # Validate tags in this docstring
        for key in tag_keys:
            if key not in ['internal', 'block', 'module', 'class', 'datatype', 'function',
                           'property', 'table', 'tparam', 'param', 'treturn', 'return',
                           'tfield', 'raise', 'usage', 'category', 'signature']:
                raise ValueError("Unknown tag \"{}\" encountered in docstring: \"{}\"".format(key, docstring))

        if 'internal' in tag_keys:
            # Skip internal documentation
            pass
        elif 'block' in tag_keys:
            doc = decode_docstring_block(docstring)
            docs.append(doc)
            namespace = doc
        elif 'module' in tag_keys:
            doc = decode_docstring_module(docstring)
            docs.append(doc)
            namespace = doc
        elif 'class' in tag_keys:
            doc = decode_docstring_class(docstring)
            if namespace:
                namespace.children.append(doc)
            else:
                docs.append(doc)
                namespace = doc
        elif 'datatype' in tag_keys:
            doc = decode_docstring_datatype(docstring)
            if namespace:
                namespace.children.append(doc)
            else:
                docs.append(doc)
                namespace = doc
        elif 'function' in tag_keys:
            doc, cls = decode_docstring_function(docstring)

            parent = next(filter(lambda d: d.name == cls, docs + namespace.children), None)
            if parent:
                parent.children.append(doc)
            else:
                assert namespace, "Function docstring \"{}\" has no namespace.".format(doc.name)
                namespace.children.append(doc)
        elif 'property' in tag_keys:
            doc, cls = decode_docstring_property(docstring)

            parent = next(filter(lambda d: d.name == cls, docs + namespace.children), None)
            if parent:
                parent.children.append(doc)
            else:
                assert namespace, "Property docstring \"{}\" has no namespace.".format(doc.name)
                namespace.children.append(doc)
        elif 'table' in tag_keys:
            doc = decode_docstring_table(docstring)
            assert namespace, "Table docstring \"{}\" has no namespace.".format(doc.name)
            namespace.children.append(doc)
        else:
            raise ValueError("Unsupported docstring. Missing @block, @class, @module, @datatype, @function, @property, or @table tag. Docstring: \"{}\".".format(docstring))

    return docs


################################################################################
# Organization
################################################################################


def organize_docs(docs):
    blocks = {}
    modules = {}
    datatypes = {}

    for doc in docs:
        if isinstance(doc, BlockDoc):
            if doc.category not in blocks:
                blocks[doc.category] = []
            blocks[doc.category].append(doc)
        elif isinstance(doc, ModuleDoc):
            modules[doc.name] = doc
        elif isinstance(doc, DatatypeDoc):
            datatypes[doc.name] = doc
        else:
            raise ValueError("Unknown top-level doc type \"{}\".".format(type(doc)))

    for category in blocks:
        blocks[category] = sorted(blocks[category], key=lambda b: b.name)

    return blocks, modules, datatypes


################################################################################
# Debug dump
################################################################################


def dump(blocks, modules, datatypes):
    s = []

    s.append("Blocks")
    for category in blocks:
        s.append("\t" + category)
        for block in blocks[category]:
            s.append("\t\t{} ({})".format(block.name, type(block).__name__))
            if hasattr(block, "children"):
                for child in block.children:
                    s.append("\t\t\t{} ({})".format(child.name, type(child).__name__))

    s.append("Modules")
    for name in modules:
        s.append("\t{} ({})".format(name, type(modules[name]).__name__))
        for child in modules[name].children:
            s.append("\t\t{} ({})".format(child.name, type(child).__name__))
            if hasattr(child, "children"):
                for subchild in child.children:
                    s.append("\t\t\t{} ({})".format(subchild.name, type(subchild).__name__))

    s.append("Datatypes")
    for name in datatypes:
        s.append("\t{} ({})".format(name, type(datatypes[name]).__name__))
        for child in datatypes[name].children:
            s.append("\t\t{} ({})".format(child.name, type(child).__name__))

    return "\n".join(s)


################################################################################
# Top-level
################################################################################

if __name__ == "__main__":
    docs = []

    for filename in glob.iglob('../../radio/**/*.lua', recursive=True):
        # Skip thirdparty libraries
        if filename.startswith('../../radio/thirdparty/'):
            continue

        comments = parse_file(filename)
        docstrings = parse_comments(comments)
        docs += decode_docstrings(docstrings)

    # Organize docs into blocks, modules, datatypes categories
    blocks, modules, datatypes = organize_docs(docs)

    # Dump organized docs to stdout
    sys.stderr.write(dump(blocks, modules, datatypes) + "\n")

    # Templatize reference manual
    escape_markdown_headers = lambda s: re.sub(r"([#]+)", r'${"\1"}', s)
    refman_template = mako.template.Template(filename="refman.template.md",
                                             lookup=mako.lookup.TemplateLookup(directories=['./'],
                                                                               input_encoding='utf-8',
                                                                               preprocessor=escape_markdown_headers),
                                             preprocessor=escape_markdown_headers)

    sys.stdout.write(refman_template.render(blocks=blocks, modules=modules, datatypes=datatypes,
                                            ModuleDoc=ModuleDoc, BlockDoc=BlockDoc, DatatypeDoc=DatatypeDoc,
                                            ClassDoc=ClassDoc, FunctionDoc=FunctionDoc, PropertyDoc=PropertyDoc,
                                            FieldDoc=FieldDoc))
