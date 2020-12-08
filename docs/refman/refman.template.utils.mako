<%!

import os
import re
import subprocess

git_version = os.environ.get("GIT_VERSION") or subprocess.check_output("git describe --abbrev --always --tags".split(" ")).decode().strip()

disable_toc = os.environ.get("DISABLE_TOC")

block_categories = [
    "Sources",
    "Sinks",
    "Filtering",
    "Math Operations",
    "Level Control",
    "Sample Rate Manipulation",
    "Spectrum Manipulation",
    "Carrier and Clock Recovery",
    "Digital",
    "Type Conversion",
    "Miscellaneous",
    "Modulation",
    "Demodulation",
    "Protocol",
    "Receivers"
]

def format_arglist(parameters):
    required = ", ".join([p.name for p in parameters if not p.default])
    optional = ", ".join(["{}={}".format(p.name, p.default) for p in parameters if p.default])
    if required and optional:
        return required + "[, " + optional + "]"
    elif required and not optional:
        return required
    elif optional and not required:
        return "[" + optional + "]"
    else:
        return ""

def format_typelist(types):
    return "\\|".join(["*{}*".format(t) for t in types.split("|")])

def normalize_multiline(s):
    if "*" in s:
        s = re.sub(r"\n( )+", "\n      ", s)
        s = re.sub(r"\n( )+\*", "\n    *", s)
        return s
    else:
        return s.replace("\n", "\n ")

def wrap_div(name):
    def decorator(fn):
        def wrapped(context, *args, **kw):
            context.write('<div class="{}">\n'.format(name))
            fn(*args, **kw)
            context.write('</div>\n')
            return ''
        def unwrapped(context, *args, **kw):
            fn(*args, **kw)
            return ''
        return wrapped if os.environ.get("WRAP_DIVS") else unwrapped
    return decorator

%>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Render (top-level) """
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

<%def name='render(element, namespace="", separator=True)'>\
% if isinstance(element, ModuleDoc):
${render_module(element, namespace)}\
% elif isinstance(element, BlockDoc):
${render_block(element, namespace)}\
% elif isinstance(element, DatatypeDoc):
${render_class(element, namespace)}\
% elif isinstance(element, ClassDoc):
${render_class(element, namespace)}\
% elif isinstance(element, FunctionDoc):
${render_function(element, namespace)}\
% elif isinstance(element, PropertyDoc):
${render_property(element, namespace)}\
% elif isinstance(element, FieldDoc):
${render_field(element, namespace)}\
% else:
<%  raise ValueError("Unknown element type: {}".format(type(element))) %>
% endif
% if separator and not isinstance(element, ModuleDoc):
--------------------------------------------------------------------------------
% endif
</%def>\

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Render Module """
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

<%def name="render_module(module, namespace)">\
${module.description}
% for child in module.children:

${render(child, module.name + ".")}\
% endfor
</%def>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Render Block """
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

<%def name="render_block(block, namespace)" decorator="wrap_div('block')">\
#### ${block.name}

${block.description}

##### `${namespace}${block.name}(${format_arglist(block.parameters)})`
% if block.parameters:

###### Arguments

% for arg in block.parameters:
%   if arg.type:
* `${arg.name}` (${format_typelist(arg.type)}): ${normalize_multiline(arg.description)}
%   else:
* `${arg.name}`: ${normalize_multiline(arg.description)}
%   endif
% endfor
% endif

###### Type Signatures

% for signature in block.signatures:
<%
    inputs = ", ".join(["`{}` *{}*".format(*input) if input.type else "`{}`".format(input.name) for input in signature.inputs])
    outputs = ", ".join(["`{}` *{}*".format(*output) if output.type else "`{}`".format(output.name) for output in signature.outputs])
%>\
%   if signature.inputs and signature.outputs:
* ${inputs} ➔❑➔ ${outputs}
%   elif signature.inputs:
* ${inputs} ➔❑
%   elif signature.outputs:
* ❑➔ ${outputs}
%   endif
%endfor

###### Example

``` lua
${block.usage}
```

% if block.children:

% for child in block.children:
${render(child, namespace, separator=False)}\
% endfor
% endif
</%def>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Render Class """
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

<%def name="render_class(cls, namespace)" decorator="wrap_div('class')">\
#### ${cls.name}

##### `${namespace}${cls.name}(${format_arglist(cls.parameters)})`

${cls.description}

% if cls.parameters:
###### Arguments

% for arg in cls.parameters:
%   if arg.type:
* `${arg.name}` (${format_typelist(arg.type)}): ${normalize_multiline(arg.description)}
%   else:
* `${arg.name}`: ${normalize_multiline(arg.description)}
%   endif
% endfor

% endif
% if hasattr(cls, 'usage') and cls.usage:
###### Example

``` lua
${cls.usage}
```

% endif
% for child in cls.children:
${render(child, separator=False)}\
% endfor
</%def>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Render Function """
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

<%def name="render_function(func, namespace)" decorator="wrap_div('function')">\
##### `${namespace}${func.name}(${format_arglist(func.parameters)})`

${func.description}
% if func.parameters:

###### Arguments

% for arg in func.parameters:
%   if arg.type:
* `${arg.name}` (${format_typelist(arg.type)}): ${normalize_multiline(arg.description)}
%   else:
* `${arg.name}`: ${normalize_multiline(arg.description)}
%   endif
% endfor
% endif
% if func.returns:

###### Returns

% for ret in func.returns:
* ${normalize_multiline(ret.description)} (${format_typelist(ret.type)})
% endfor
% endif
% if func.raises:

###### Raises

% for r in func.raises:
* ${r}
% endfor
% endif
% if func.usage:

###### Example

``` lua
${func.usage}
```
%endif

</%def>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Render Property """
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

<%def name="render_property(prop, namespace)" decorator="wrap_div('function')">\
##### `${namespace}${prop.name}`

${prop.description}
% if prop.returns:

###### Returns

% for ret in prop.returns:
* ${normalize_multiline(ret.description)} (${format_typelist(ret.type)})
% endfor
% endif
% if prop.raises:

###### Raises

% for r in prop.raises:
* ${r}
% endfor
% endif
% if prop.usage:

###### Example

``` lua
${prop.usage}
```
%endif

</%def>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""" Render Field """
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

<%def name="render_field(field, namespace)" decorator="wrap_div('field')">\
##### `${namespace}${field.name}`

*${field.type}*: ${field.description}

</%def>
