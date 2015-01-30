# YAC
#### Yeat Another Console

***New conception of Traffic Monitor(TM) frontend development workflow with a different batch of techniques, technologies and frameworks.***

### 1. Motivation

After YAP developing, i have some frustration about product quality. A lot of arhitecture defects were resolved in next version, which is under development at the moment. But i still feel DRY (don't repeat youself) approach deficiency. Now we use Marrionette behaviours, but it's still not comprehensive DRY technique: we still use css selectors to manipulate dom, behaviours are still state-missing (have not state flow or finite state machine). Marionette gives us an extra development manner freedom, the consequence of which is expressed by code inconsistency. 

### 2. Inspiration 
I think that development flow must be fast, productive and unambiguous. We should not waste time in making Code Design (CD) decisions. In this case the most productive and modern approach will be web components usage. React.js may be the perfect solution. It has some inconvenience for some developers, but i'm going to present the more complex solution, rather than a framework.

The text below was written under inspiration of using net tools of web-stack:
- Gulp<sup>*</sup>  - workflow automator and source build system
- React - js library for building ui
- Cjxs  - Jsx transpiler with coffeescript support
- Yaml<sup>*</sup>  - very simple and powerfull markup language for static data structures
- Karma<sup>*</sup> - spectacular test runner for javascript
- Codo  - documentation generator

\* - tools, which integration is not *complete* in current TM

### 3. Style Guide
All of us love clean code and all of us has it's own code style guide. It's strongly recommended to have common documented team style guide. My vision of code is represented in section below.

#### 3.1. Coffeescript style guide
Most of critical cases are covered with coffee linter. 

For convenience l'll some shortenings are used:
✓ - to mark *good* practices
☝ - covered with coffee linter
✗ \[explanation\] - to mark *bad* practices

##### Special chars
- Use only 2 spaces for identation☝. 
- Chars limit per line is 80☝. 
- Use double quotes for strings.

###### Blank Lines
Separate top-level function and class definitions with a *single* blank line.It's *strongly recomended* to avoid line breaks in context of block (only comments may break code inside code block).
```coffee
a = "foo"
✓ 
class Foo
    ✓ 
    contructor: ->
        bar()
        ✗ inside block
        baz()

    ✗ extra
    bar()
```

###### Optional commas
Multiline arrays/objects should not contain commas.
```coffee
foo = [
  'bar' ✓ 
  'baz', ✗
  bar:
    bear: 2
    vodka: [
        "beluga premium"
    ] ✓ comply identation
]
```

##### Comments
All comments should be meaningful, and should not just repeat code sense.

###### Inline comments
Inline comments should be used *only* inside functions. First letter of the comment should be uppercased.
```coffee
# My super class ✗
class Bar

  # function documentation ✗
  foo (a) = ->
    # inc ✗
    a++
    # Decrement before return ✓
    --a
```

###### Block comments
Block comments should be used to document functions, classes, it's methods and properties. Block comments should be started with `###*` and ended with `###`. Each line inside block comment should be prefixed with ` *` (with extra space). Usage of new lines in block comments is not recommended.
```coffee
###*
 * Bar class description
 * @deprecated
###
class Bar
    
  ###* ✓
   * Class version
   * ✗ 
   * @type {String}
  ### ✓
  version = "0.0.1"

  ###*
   * Constructor description
   * may be multiline.
   * @param  {Number} bear
   * @param  {Number} water
   * @return {Bar}
  ### 
  constructor: (bear, water) ->
    bear  *= 2
    water /= 2

```


Правила описания
```json
{
    "feature": "Функция|Функционал|Свойство",
    "background": "Предыстория|Контекст",
    "scenario": "Сценарий",
    "scenario_outline": "Структура сценария",
    "examples": "Примеры",
    "given": "*|Допустим|Дано|Пусть",
    "when": "*|Если|Когда",
    "then": "*|То|Тогда",
    "and": "*|И|К тому же|Также",
    "but": "*|Но|А"
}
```

# test

![test](http://tardis1.tinygrab.com/grabs/a25d0cc4c172c8180ea6c8b587a2d4a4cf404fd03a.png)
