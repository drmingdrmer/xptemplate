XPTemplate priority=lang keyword=:%#

" containers
let s:f = XPTcontainer()[0]

" inclusion
XPTinclude
      \ _common/common

" ========================= Function and Variables =============================

fun! s:f.RubyCamelCase(...) "{{{
  let str = a:0 == 0 ? self.V() : a:1
  let r = substitute(substitute(str, "[\/ _]", ' ', 'g'), '\<.', '\u&', 'g')
  return substitute(r, " ", '', 'g')
endfunction "}}}

fun! s:f.RubySnakeCase(...) "{{{
  let str = a:0 == 0 ? self.V() : a:1
  return substitute(str," ",'_','g')
endfunction "}}}

" Multiple each snippet {{{
"{{{ s:each_list
let s:each_list = [ 'byte', 'char', 'cons', 'index', 'key',
      \'line', 'pair', 'slice', 'value' ]
"}}}

fun! s:f.RubyEachPopup() "{{{
  let l = []
  for i in s:each_list
    let l += [{'word': i, 'menu': 'each_' . i . '{ |..| ... }'}]
  endfor
  return l
endfunction "}}}

fun! s:f.RubyEachBrace() "{{{
  let v = self.SV('^_','','')
  if v == ''
    return ''
  elseif v =~# 'slice\|cons'
    return '_' . v.'(`val^3^)'
  else
    return '_' . v
  endif
endfunction "}}}

fun! s:f.RubyEachPair() "{{{
  let v = self.R('what')
  if v =~# 'pair'
    return '`el1^, `el2^'
  elseif v == ''
    return '`el^'
  else
    if v =~ 'slice\|cons'
      let v = substitute(v,'val','','')
    endif
    return '`' . substitute(v,'[^a-z]','','g') . '^'
  endif
endfunction "}}}
" End multiple each snippet }}}

" Multiple assert snippet {{{
"{{{ s:assert_map
let s:assert_map = {
      \'block'          : ''                                                        . ' { `cursor^ }',
      \'equals'         : '(`expected^, `actual^`, `message^)'                      . '',
      \'in_delta'       : '(`expected float^, `actual float^, `delta^`, `message^)' . '',
      \'instance_of'    : '(`klass^, `object to compare^`, `message^)'              . '',
      \'kind_of'        : '(`klass^, `object to compare^`, `message^)'              . '',
      \'match'          : '(/`regexp^/`^, `string^`, `message^)'                    . '',
      \'not_equal'      : '(`expected^, `actual^`, `message^)'                      . '',
      \'nil'            : '(`object^`, `message^)'                                  . '',
      \'no_match'       : '(/`regexp^/`^, `string^`, `message^)'                    . '',
      \'not_nil'        : '(`object^`, `message^)'                                  . '',
      \'nothing_raised' : '(`exception^)'                                           . ' { `cursor^ }',
      \'not_same'       : '(`expected^, `actual^`, `message^)'                      . '',
      \'nothing_thrown' : '`(`message`)^'                                           . ' { `cursor^ }',
      \'operator'       : '(`obj1^, `operator^, `obj2^`, `message^)'                . '',
      \'raise'          : '(`exception^)'                                           . ' { `cursor^ }',
      \'respond_to'     : '(`object^, `respond to this message^`, `message^)'       . '',
      \'same'           : '(`expected^, `actual^`, `message^)'                      . '',
      \'send'           : '([`receiver^, `method^, `args^]`, `message^)'            . '',
      \'throws'         : '(`expected symbol^`, `message^)'                         . ' { `cursor^ }',
      \}
"}}}

fun! s:RubyAssertPopupSort(a, b) "{{{
  return a:a.word > a:b.word
endfunction "}}}

fun! s:f.RubyAssertPopup() "{{{
  let list = []
  for [k, v] in items(s:assert_map)
    let list += [{ 'word' : k, 'menu' : 'assert_' . k . substitute(v, '`.\{-}^', '..', 'g') }]
  endfor
  return sort(list, 's:RubyAssertPopupSort')
endfunction "}}}

fun! s:f.RubyAssertMethod() "{{{
  let v = self.SV('^_', '', '')
  if v == ''
    return v . '(`^`, `message^)'
  endif
  if has_key(s:assert_map, v)
    return '_' . v . s:assert_map[v]
  else
    return ''
  endif
endfunction "}}}
" End multiple assert snippet }}}

" Repeat an item inside its edges.
" Behave like ExpandIfNotEmpty() but within edges
fun! s:f.RepeatInsideEdges(sep) "{{{
  let [edgeLeft, edgeRight] = self.ItemEdges()
  let v = self.V()
  let n = self.N()
  if v == '' || v == self.ItemFullname()
    return ''
  endif


  let v = self.ItemStrippedValue()
  let [ markLeft, markRight ] = XPTmark()

  let newName = 'n' . n
  let res  = edgeLeft . v
  let res .= markLeft . a:sep .  markLeft . newName . markRight 
  let res .= 'ExpandIfNotEmpty("' . a:sep . '", "' . newName . '")' . markRight . markRight
  let res .=  edgeRight


  return res
endfunction "}}}

" Remove an item if its value hasn't change
fun! s:f.RemoveIfUnchanged() "{{{
  let v = self.V()
  let [lft, rt] = self.ItemEdges()
  if v == lft . self.N() . rt
    return ''
  else
    return v
  end
endfunction "}}}

" ================================= Snippets ===================================
XPTemplateDef

XPT # hint=#{..} syn=string
XSET _=
#{`_^}


XPT : hint=:...\ =>\ ...
:`key^ => `value^


XPT % hint=%**[..]
XSET _=Q
XSET content=
%`_^[`content^]


XPT BEG hint=BEGIN\ {\ ..\ }
BEGIN {
    `cursor^
}


XPT Comp hint=include\ Comparable\ def\ <=>\ ...
include Comparable

def <=>(other)
    `cursor^
end


XPT END hint=END\ {\ ..\ }
END {
    `cursor^
}


XPT Enum hint=include\ Enumerable\ def\ each\ ...
include Enumerable

def each(&block)
    `cursor^
end


XPT Forw hint=extend\ Forwardable
extend Forwardable


XPT Md hint=Marshall\ Dump
XSET file=file
File.open("`filename^", "wb") { |`file^| Marshal.dump(`obj^, `file^) }


XPT Ml hint=Marshall\ Load
XSET file=file
File.open("`filename^", "rb") { |`file^| Marshal.load(`file^) }


XPT Pn hint=PStore.new\(..)
PStore.new("`filename^")


XPT Yd hint=YAML\ dump
XSET file=file
File.open("`filename^.yaml", "wb") { |`file^| YAML.dump(`obj^,`file^) }


XPT Yl hint=YAML\ load
XSET file=file
File.open("`filename^.yaml") { |`file^| YAML.load(`file^) }


XPT _d hint=__DATA__
__DATA__


XPT _e hint=__END__
__END__


XPT _f hint=__FILE__
__FILE__


XPT ali hint=alias\ :\ ..\ :\ ..
XSET new.post=RubySnakeCase()
XSET old=old_{R("new")}
XSET old.post=RubySnakeCase()
alias :`new^ :`old^


XPT all hint=all?\ {\ ..\ }
all? { |`element^| `cursor^ }


XPT amm hint=alias_method\ :\ ..\ :\ ..
XSET new.post=RubySnakeCase()
XSET old=old_{R("new")}
XSET old.post=RubySnakeCase()
alias_method :`new^, :`old^


XPT any hint=any?\ {\ |..|\ ..\ }
any? { |`element^| `cursor^ }


XPT app hint=if\ __FILE__\ ==\ $PROGRAM_NAME\ ...
if __FILE__ == $PROGRAM_NAME
    `cursor^
end


XPT array hint=Array.new\(..)\ {\ ...\ }
XSET arg=i
XSET size=5
Array.new(`size^) { |`arg^| `cursor^ }

XPT ass hint=assert**\(..)\ ...
XSET what=RubyAssertPopup()
XSET what|post=RubyAssertMethod()
XSET message|post=RemoveIfUnchanged()
assert`_`what^


XPT attr hint=attr_**\ :...
XSET what=Choose(["accessor", "reader", "writer"])
XSET what|post=SV("^_$",'','')
XSET attr*|post=ExpandIfNotEmpty(', :', 'attr*')
attr`_`what^ :`attr*^
..XPT

XPT begin hint=begin\ ..\ rescue\ ..\ else\ ..\ end
XSET block=# block
begin
    `expr^
``rescue...`
{{^rescue `Exception^` => `e^
    `block^
``rescue...`
^`}}^``else...`
{{^else
    `block^
`}}^``ensure...`
{{^ensure
    `cursor^
`}}^end

XPT bm hint=Benchmark.bmbm\ do\ ...\ end
XSET times=10_000
TESTS = `times^

Benchmark.bmbm do |result|
    `cursor^
end


XPT case hint=case\ ..\ when\ ..\ end
XSET block=# block
case `target^`
when `comparison^
    `block^
``when...`
{{^when `comparison^
    `block^
``when...`
^`}}^``else...`
{{^else
    `cursor^
`}}^end


XPT cfy hint=classify\ {\ |..|\ ..\ }
classify { |`element^| `cursor^ }


XPT cl hint=class\ ..\ end
XSET ClassName.post=RubyCamelCase()
class `ClassName^
    `cursor^
end


XPT cld hint=class\ ..\ <\ DelegateClass\ ..\ end
XSET ClassName.post=RubyCamelCase()
XSET ParentClass.post=RubyCamelCase()
XSET arg*|post=RepeatInsideEdges(', ')
class `ClassName^ < DelegateClass(`ParentClass^)
    def initialize`(`arg*`)^
        super(`delegate object^)

        `cursor^
    end
end


XPT cli hint=class\ ..\ def\ initialize\(..)\ ...
XSET ClassName|post=RubyCamelCase()
XSET name|post=RubySnakeCase()
XSET init=Trigger('defi')
XSET def=Trigger('def')
class `ClassName^
    `init^`
    `def...^

    `def^`
    `def...^
end


XPT cls hint=class\ <<\ ..\ end
XSET self=self
class << `self^
    `cursor^
end


XPT clstr hint=..\ =\ Struct.new\ ...
XSETm do...|post
 do
    `cursor^
end
XSETm END
XSET ClassName|post=RubyCamelCase()
XSET attr*|post=RepeatInsideEdges(', :')
`ClassName^ = Struct.new`(:`attr*`)^` `do...^


XPT col hint=collect\ {\ ..\ }
collect { |`obj^| `cursor^ }


XPT deec hint=Deep\ copy
Marshal.load(Marshal.dump(`obj^))


XPT def hint=def\ ..\ end
XSET method|post=RubySnakeCase()
XSET arg*|post=RepeatInsideEdges(', ')
def `method^`(`arg*`)^
    `cursor^
end


XPT defd hint=def_delegator\ :\ ...
def_delegator :`del obj^, :`del meth^, :`new name^


XPT defds hint=def_delegators\ :\ ...
def_delegators :`del obj^, :`del methods^


XPT defi hint=def\ initialize\ ..\ end
XSET arg*|post=RepeatInsideEdges(', ')
def initialize`(`arg*`)^
    `cursor^
end


XPT defmm hint=def\ method_missing\(..)\ ..\ end
def method_missing(meth, *args, &block)
    `cursor^
end


XPT defs hint=def\ self...\ end
XSET method.post=RubySnakeCase()
XSET arg*|post=RepeatInsideEdges(', ')
def self.`method^`(`arg*`)^
    `cursor^
end


XPT deft hint=def\ test_..\ ..\ end
XSET name|post=RubySnakeCase()
XSET arg*|post=RepeatInsideEdges(', ')
def test_`name^`(`arg*`)^
    `cursor^
end


XPT deli hint=delete_if\ {\ |..|\ ..\ }
delete_if { |`arg^| `cursor^ }


XPT det hint=detect\ {\ ..\ }
detect { |`obj^| `cursor^ }


XPT dir hint=Dir[..]
XSET _='/**/*'
Dir[`_^]


XPT dirg hint=Dir.glob\(..)\ {\ |..|\ ..\ }
XSET d=file
Dir.glob('`dir^') { |`f^| `cursor^ }


XPT do hint=do\ |..|\ ..\ end
XSET arg*|post=RepeatInsideEdges(', ')
do` |`arg*`|^
    `cursor^
end


XPT dow hint=downto\(..)\ {\ ..\ }
XSET arg=i
XSET lbound=0
downto(`lbound^) { |`arg^| `cursor^ }


XPT each hint=each_**\ {\ ..\ }
XSET what=RubyEachPopup()
XSET what|post=RubyEachBrace()
XSET vars=RubyEachPair()
each`_`what^ { |`vars^| `cursor^ }


XPT fdir hint=File.dirname\(..)
XSET _=
File.dirname(`_^)


XPT fet hint=fetch\(..)\ {\ |..|\ ..\ }
fetch(`name^) { |`key^| `cursor^ }


XPT file hint=File.foreach\(..)\ ...
XSET line=line
File.foreach('`filename^') { |`line^| `cursor^ }


XPT fin hint=find\ {\ |..|\ ..\ }
find { |`element^| `cursor^ }


XPT fina hint=find_all\ {\ |..|\ ..\ }
find_all { |`element^| `cursor^ }


XPT fjoin hint=File.join\(..)
File.join(`dir^, `path^)


XPT fla hint=flatten_once
XSET arr=arr
XSET a=a
inject(Array.new) { |`arr^, `a^| `arr^.push(*`a^) }


XPT fread hint=File.read\(..)
File.read('`filename^')


XPT grep hint=grep\(..)\ {\ |..|\ ..\ }
XSET match=m
grep(/`pattern^/) { |`match^| `cursor^ }


XPT gsub hint=gsub\(..)\ {\ |..|\ ..\ }
XSET match=m
gsub(/`pattern^/) { |`match^| `cursor^ }


XPT hash hint=Hash.new\ {\ ...\ }
XSET hash=h
XSET key=k
Hash.new { |`hash^,`key^| `hash^[`key^] = `cursor^ }

XPT if hint=if\ ..\ end
if `boolean exp^
    `cursor^
end

XPT ife hint=if\ ..\ else\ ..\ end
XSET block=# block
if `boolean exp^
    `block^
else
    `cursor^
end

XPT ifei hint=if\ ..\ elsif\ ..\ else\ ..\ end
XSETm else...|post

else
    `cursor^
XSETm END
XSETm elsif...|post

elsif `boolean exp^
`block^`
`elsif...^
XSETm END
XSET block=# block
if `boolean exp^
    `block^`
`elsif...^`
`else...^
end


XPT inj hint=inject\(..)\ {\ |..|\ ..\ }
XSET accumulator=acc
XSET element=el
inject`(`arg`)^ { |`accumulator^, `element^| `cursor^ }


XPT lam hint=lambda\ {\ ..\ }
XSET arg*|post=RepeatInsideEdges(', ')
lambda {` |`arg*`|^ `cursor^ }


XPT loop hint=loop\ do\ ...\ end
loop do
    `cursor^
end

XPT map hint=map\ {\ |..|\ ..\ }
map { |`arg^| `cursor^ }


XPT max hint=max\ {\ |..|\ ..\ }
max { |`element1^, `element2^| `cursor^ }


XPT min hint=min\ {\ |..|\ ..\ }
min { |`element1^, `element2^| `cursor^ }


XPT mod hint=module\ ..\ ..\ end
XSET module name|post=RubyCamelCase()
module `module name^
    `cursor^
end


XPT modf hint=module\ ..\ module_function\ ..\ end
XSET module name|post=RubyCamelCase()
module `module name^
    module_function

    `cursor^
end


XPT nam hint=Rake\ Namespace
XSET ns=fileRoot()
namespace :`ns^ do
    `cursor^
end


XPT new hint=Instanciate\ new\ object
XSET Object|post=RubyCamelCase()
XSET arg*|post=RepeatInsideEdges(', ')
`var^ = `Object^.new`(`arg*`)^


XPT open hint=open\(..)\ {\ |..|\ ..\ }
XSET mode...|post=, '`wb^'
XSET wb=wb
XSET io=io
open("`filename^"`, `mode...^) { |`io^| `cursor^ }


XPT par hint=partition\ {\ |..|\ ..\ }
partition { |`element^| `cursor^ }


XPT pathf hint=Path\ from\ here
XSET path=../lib
File.join(File.dirname(__FILE__), "`path^")


XPT rdoc syn=comment hint=RDoc\ description
=begin rdoc
# `cursor^
#=end


XPT rej hint=reject\ {\ |..|\ ..\ }
reject { |`element^| `cursor^ }


XPT rep hint=Benchmark\ report
result.report("`name^: ") { TESTS.times { `cursor^ } }


XPT req hint=require\ ..
require '`lib^'


XPT reqs hint=%w[..].map\ {\ |lib|\ require\ lib\ }
XSET lib*|post=ExpandIfNotEmpty(' ', 'lib*')
%w[`lib*^].map { |lib| require lib }


XPT reve hint=reverse_each\ {\ ..\ }
reverse_each { |`element^| `cursor^ }


XPT scan hint=scan\(..)\ {\ |..|\ ..\ }
XSET match=m
scan(/`pattern^/) { |`match^| `cursor^ }


XPT sel hint=select\ {\ |..|\ ..\ }
select { |`element^| `cursor^ }


XPT shebang hint=#!/usr/bin/env\ ruby
#!/usr/bin/env ruby


XPT sinc hint=class\ <<\ self;\ self;\ end
class << self; self; end


XPT sor hint=sort\ {\ |..|\ ..\ }
sort { |`element1^, `element2^| `element1^ <=> `element2^ }


XPT sorb hint=sort_by\ {\ |..|\ ..\ }
sort_by {` |`arg`|^ `cursor^ }


XPT ste hint=step\(..)\ {\ ..\ }
XSET arg=i
XSET count=10
XSET step=2
step(`count^`, `step^) { |`arg^| `cursor^ }


XPT sub hint=sub\(..)\ {\ |..|\ ..\ }
XSET match=m
sub(/`pattern^/) { |`match^| `cursor^ }


XPT subcl hint=class\ ..\ <\ ..\ end
XSET ClassName.post=RubyCamelCase()
XSET Parent.post=RubyCamelCase()
class `ClassName^ < `Parent^
    `cursor^
end


XPT tas hint=Rake\ Task
XSET task name|post=RubySnakeCase()
XSET dep*|post=RepeatInsideEdges(', :')
desc "`task description^"
task :`task name^` => [:`dep*`]^ do
    `cursor^
end


XPT tc hint=require\ 'test/unit'\ ...\ class\ Test..\ <\ Test::Unit:TestCase\ ...
XSET ClassName=RubyCamelCase(R("module"))
XSET ClassName.post=RubyCamelCase()
XSET deft=Trigger('deft')
require "test/unit"
require "`module^"

class Test`ClassName^ < Test::Unit:TestCase
    `deft^`...^

    `deft^`...^
end


XPT tif hint=..\ ?\ ..\ :\ ..
(`boolean exp^) ? `exp if true^ : `exp if false^


XPT tim hint=times\ {\ ..\ }
times {` |`index`|^ `cursor^ }


XPT tra hint=transaction\(..)\ {\ ...\ }
XSET _=true
transaction(`_^) { `cursor^ }


XPT unif hint=Unix\ Filter
XSET line=line
ARGF.each_line do |`line^|
    `cursor^
end


XPT unless hint=unless\ ..\ end
unless `boolean cond^
    `cursor^
end


XPT until hint=until\ ..\ end
until `boolean cond^
    `cursor^
end


XPT upt hint=upto\(..)\ {\ ..\ }
XSET arg=i
XSET ubound=10
upto(`ubound^) { |`arg^| `cursor^ }


XPT usai hint=if\ ARGV..\ abort\("Usage...
XSET _=
XSET args=[options]
if ARGV`_^
  abort "Usage: #{$PROGRAM_NAME} `args^"
end


XPT usau hint=unless\ ARGV..\ abort\("Usage...
XSET _=
XSET args=[options]
unless ARGV`_^
  abort "Usage: #{$PROGRAM_NAME} `args^"
end


XPT while hint=while\ ..\ end
while `boolean cond^
    `cursor^
end


XPT wid hint=with_index\ {\ ..\ }
XSET index=i
with_index { |`element^, `index^| `cursor^ }


XPT xml hint=REXML::Document.new\(..)
REXML::Document.new(File.read("`filename^"))


XPT y syn=comment hint=:yields:
:yields:


XPT zip hint=zip\(..)\ {\ |..|\ ..\ }
XSET row=row
zip(`enum^) { |`row^| `cursor^ }




" ================================= Wrapper ===================================



XPT invoke_ hint=..(SEL)
XSET name.post=RubySnakeCase()
`name^(`wrapped^)


XPT def_ hint=def\ ..()\ SEL\ end
XSET _.post=RubySnakeCase()
def `_^`(`args`)^
    `wrapped^
end


XPT class_ hint=class\ ..\ SEL\ end
XSET _.post=RubyCamelCase()
class `_^
    `wrapped^
end


XPT module_ hint=module\ ..\ SEL\ end
XSET _.post=RubyCamelCase()
module `_^
    `wrapped^
end


XPT begin_ hint=begin\ SEL\ rescue\ ..\ else\ ..\ end
XSET block=# block
begin
    `wrapped^
``rescue...`
{{^rescue `Exception^` => `e^
    `block^
``rescue...`
^`}}^``else...`
{{^else
    `block^
`}}^``ensure...`
{{^ensure
    `cursor^
`}}^end

