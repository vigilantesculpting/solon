# solon
```Solon``` is a simple text templating engine

It aims to add conditional, looping and composition to text files, specifically aimed at but not limited to generating HTML from templates. 

```solon``` uses simple markers to embed its code, and uses [pretzyl](https://github.com/vigilantesculpting/pretzyl) for the evaluation of statements in conditionals and as text replacement / filtering. ```pretzyl``` is a forth-like stack-based interpreted language, and as such ```solon``` does not (ab)use ```eval```, but instead provides a safe but powerful interpretation environment.

```solon``` can define pieces of text as functions, and can call these to either replace or wrap a specific piece of text, passing arguments to the called function. One template can import another, which makes all definitions in the importee available in the importer, and adds any output text from the importee at the point of import in the importer.

## Template example:

A quick example of the syntax
```html
<ul>
	%for fruit fruitinfo: fruits iteritems
		%if fruitinfo/count 7 >
			<li>I have enough {{ fruitinfo/color }} {{ fruit }}</li>
		%else
			<li>I don't have enough {{ fruitinfo/color }} {{ fruit }}<</li>
		%end
	%end
</ul>
```

## Usage:

Here is a quick usage example with the above-mentioned template
```python
import solon

s = solon.Solon({
	'fruits/apples/color': 'red',
	'fruits/apples/count': 5,

	'fruits/oranges/color': 'orange',
	'fruits/oranges/count': 10,
})
s.addtemplate('template', """
<ul>
	%for fruit fruitinfo: fruits iteritems
		%if fruitinfo/count 7 >
			<li>I have enough {{ fruitinfo/color }} {{ fruit }}</li>
		%else
			<li>I don't have enough {{ fruitinfo/color }} {{ fruit }}</li>
		%end
	%end
</ul>
""")
print s.render('template')
```
Running this will produce the output
```text
<ul>
			<li>I don't have enough red apples<</li>
			<li>I have enough orange oranges</li>
</ul>
```
```Solon``` implements an environment using the dict-like [NSDict](https://github.com/vigilantesculpting/nsdict), which feeds the parameters and expressions in the template during rendering.

NSDict is a namespaced dictionary, so a query like ```'users/foo'``` in the above example would return another dict with entries ```{ 'username': 'foo', 'url': 'http://foo.com', 'age': 25 }```

This allows solon to organise a bunch of information in a structured way.

## Line syntax:

Each line in a ```solon``` template consists of text, a command, and a comment. Each part is optional, but they appear in that order:
- Commands start with ```%```, and comments start with ```%-``` or ```%#```
- Everything after the start of a comment is part of the comment
- Everything before the start of a command is text

For example, the text ```<p>hello</p> %set 'key': 42 %- setting the key...``` consists of
- a piece of text ```<p>hello</p>```,
- a command ```%set 'key': 42``` and 
- a comment ```%- setting the key...```

Multiple commands are not allowed on one line.

## Commands:

Some commands in solon are single-lines, others are block commands.
Block commands have a body made up of other commands, which are terminated with an ```%end``` command.

When a command ends, any output is embedded in the parent block that contains the command.

In the descriptions below, a couple of terms are used:
- ```<EXPRESSION>``` This is an expression that is fully evaluated to determine a result. Some commands, like ```%if```,
user the result as a predicate (```True``` or ```False```), and others use it to determine values (eg. ```%for```) or
output (```%set```).
- ```[NAMEEXPR]``` This is an expression that is evaluated to determine the name of a potential variable. The name
should be a token that is acceptable as a name by ```pretzyl```.
- ```[NAME]``` This is a bare ```pretzyl``` token name. It is not evaluated, since it is usually used for declaring 
a new not-yet-existing variable.
- ```[NAMELIST]``` This is a list of bare ```NAME```s

### Bare text:
```html
	This is a piece of bare text with an embedded calculation: {{ 4 2 * }}
```
Bare text is not really a command (being part of the text), but any expressions in bare text
are evaluated using pretzyl, and the result of the expression appears in the output text.

So in the example, after evaluation the text would read
```text
	This is a bare text with an embedded calculation: 8
```

### Conditionals:

#### %if...

```html
	if <EXPRESSION>
		...
	%elif <EXPRESSION>
		...
	%else
		...
	%end
```

Conditionals follow the familiar ```if elif else``` format. They are block commands, so the final conditional
must be closed with an ```%end``` command. Each conditional has its own body.

The body of the first conditional whose ```EXPRESSION``` evaluates to ```True```, is processed and its output added to the
parent block.

### Loops:

#### %for

```html
	%for [NAMELIST]: <EXPRESSION>
		...
	%end
```

Loops follow the ```var in values``` format.
```NAMELIST``` is a list of bare names. These are matched up with items from the expression, after it is evaluated.
For each pairing, the body of the loop is processed. All results are added to the enclosing block's results.

### Variables:
```html
	%set <NAMEEXPR>: <EXPRESSION>
```
This command evaluates the ```NAMEEXPR``` to determine a name, and the ```EXPRESSION``` to determine a value.
It then adds a local variable using the name and the value to the current scope.

It does not add output to the current block.

#### %write

```html
	%write <NAMEEXPR>
		...
	%end
```
This command evaluates the ```NAMEEXPR``` to determine a name, then evaluates the body of the command to determine
a text value. It then adds a local variable using the name and the value.

This command does not add output to the current block.

#### %output

```html
	%output <NAMEEXPR>
		...
	%end
```
This command evaluates the ```NAMEEXPR``` to determina a name, then avaluates the body to determine a text value.
The resultant text is added to the namespace ```output``` in the current scope.

The ```output``` namespace is special; when the current block finishes, and control passes back to the enclosing block, all local variables are discarded, except for the ```output``` namespace; this namespace is merged with the same namespace in the enclosing block. This allowes one way of retrieving multiple pieces of output from the template's evaluation (See the section name "Output" below).

#### %embed

```html
	%embed [NAMEEXPR]*
```

This construct adds the value of the evaluated ```NAMEEXPR``` to the current block's output. If ```NAME``` is ommitted, the value of the special variable ```__embed___``` is added to the current block's output. This is used by wrapping functions (see below).

### Functions:

#### %func
```html
	%func [NAME]: [NAMELIST]*
		...
	%end
```

This declares a function using the ```NAME```. The function can take an optional list of named parameters, specified
in ```NAMELIST```, which should be a list of pure names.

The body of the function is registered in the current scope, and is available for calling using either ```call``` or ```wrap```. The body of the function is not evaluated at this time, and this command produces no output.

#### %call

```html
	$call [NAMEXPR]: [PARAMLIST]
```
TODO

#### %wrap

```html
	$wrap [NAMEXPR]: [PARAMLIST]
		...
	$end
```
This command allows a kind of psuedo-inheritance: the function that is called using the evaluated ```NAMEXPR``` is processed *after* the body of the ```%wrap``` block is evaluated. At any point in time, when the wrapping function uses the ```%embed``` command, the output of the wrapped body is inserted in the wrapping function.

Finally, the resulting output of the wrapping function is inserted into its enclosing body.

This "inside-out" style of function calling allows a piece of template code to extend a "base-class" template function definition, and override part of the base-class with its own implementation.

For example, 

```html
	%func page: title
	<html>
		<head></head>
		<body>
			<title>{{ title }}</title>
			%embed
		</body>
	</html>
	%end
	%wrap page: "Fruit pantry!"
		<p>Hi and welcome to my fruit pantry page</p>
	%end
```
will result in the output
```text
	<html>
		<head></head>
		<body>
			<title>Fruit pantry!</title>
		<p>Hi and welcome to my fruit pantry page</p>
		</body>
	</html>
```
### Flow control:

#### %end
```html
	%end
```
TODO

#### %exit

```html
	%exit
```
TODO

#### %halt

```html
	%halt
```
TODO: not implemented yet

#### %continue

```html
	%continue
```
TODO: not implemented yet

### Importing other code:

#### %import

Finally, the last command is ```import```

```html
	%import [NAMEEXPR]
```

This command evaluates the template referenced by ```NAMEEXPR``` directly in the current context, adding the output
of the evaluation to the calling block's output and making all top-level function / variable declerations available
to the importing block.

## Output:

Once a template has been rendered, there are two of ways of retrieving the rendered data.

### Option 1: Solon.render()

The first is to use the result returned by the ```Solon.render``` method. For simple templates that do not
use %output to render multiple templates from a single template file, this will be the easiest.

### Option 2: Inspecting the ```output``` namespace

Each time a template uses the ```%output``` command, a variable is created with the output of the command.
This variable will be created in the ```output``` namespace of the current scope. These ```output``` namespaces
are consolidated each time a block finished processing.

Once the entire template has been rendered, the resultant ```output``` namespace will contain all outputs,
referenced by the names in the ```%output``` commands that created them.

Therefore iterating over the namespace using

```python
for key in solon.output.paths():
	print "key:", key, "-> content:", solon.output.key
```
should suffice.

## Error handling:

Care has been taken to make sure that every error in a template, even in a ```pretzyl``` expression, is properly 
propagated to the user. Files, line numbers and the solon callstack are all readily available to determine why 
a template failed to evaluate properly.

Here are the most common examples (each piece of template is followed by the error message):

### Illegal ```pretzyl``` references
If a name token cannot be resolved by ```pretzyl```, the error will look something like this (ommitting the python stacktrace output):

```html
	{{ usersdoesnotexit }} does not exit.
	>>
	solon.ExecutionError: reference to [usersdoesnotexit] not found in environment
	block [for]: 'user userinfo: usersdoesnotexit iteritems' from template/for:3
```
In this examnple, it appears that the reference to ```usersdoesnotexit``` is illegal. Either the reference name is wrong, or the entry was not declared before the reference was made.


### Errors in ```pretzyl``` expressions

```html
	%set 'hello': 'Jack' ' ' 'Beanstalk' ++
	>>
	solon.ExecutionError: reference to [++] not found in environment
	block [set]: ''hello': 'Jack' ' ' 'Beanstalk' ++' from template/set:1
```
tells us that the operator ```++``` was not found. The author probably meant to use ```+*``` (the add-collapse operator).

Similarly,
```html
	%set 'hello': 'Jack' 5 'Beanstalk' +*
	>>
	solon.ExecutionError: TypeError("unsupported operand type(s) for +: 'int' and 'str'",)
		error applying operator [<function add at 0xdeadbeef>]
	block [set]: ''hello': 'Jack' 5 'Beanstalk' +*' from template/set:1
```
tells us that there is an integer '5' which cannot be added to a string 'Beanstalk'.

### Function definition problems

A function with a bad parameer definition:
```html
	%func hello: 'name'
		<p>Hello {{name}}!</p>
	%end
	%call hello: 'Jack'
	>>
	solon.ExecutionError: bad parameter [name] in parameter list expr: [ 'name']
	block [func]: 'hello: 'name'' from template/func:1
```
Parameters have to be valid ```pretzyl``` tokens. In this case, the author probably meant to write ```%func hello: name```.

### Function call problems

Functions and calls with mismatched arguments and parameters:
```html
	%func hello: name surname
		<p>Hello {{ name }} {{surname}}!</p>
	%end
	%call hello: 'Jack' 'Beanstalk' 'Climber'
	>>
	solon.ExecutionError: func [hello] takes 2 arguments (3 given)
	block [call]: 'hello: 'Jack' 'Beanstalk' 'Climber'' from template/call:4
```
Clearly, Jack has too many names.

### Syntax Errors: unparseable commands

Bare ```%```s can trip up a template:
```html
	some text %unknowncommand %- a comment
	>>>
	solon.SyntaxError: could not parse command [%unknowncommand]
```
Perhaps the author wanted ```%unknowncommand``` to be part of the text, in which case the leading ```%``` should be escaped, 
as in ```some text %%unknowncommand %- a comment```.

### Syntax Errors: unclosed blocks

The following friendly template is missing some ```%end```s. Can you tell which ones?
```html
	%func hello: name
		%for i: 20 range
			<p>Hello {{name}}!</p>
	%call hello: 'Jack'
	>>
	solon.SyntaxError: Missing closing %ends:
		block [for] from template/func/for:2
		block [func] from template/func:1
```

