XPTemplate priority=lang mark=`~

let s:f = g:XPTfuncs()

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL
XPTvar $VOID_LINE /* void */;
XPTvar $BRif \n

XPTinclude
      \ _common/common
      \ _preprocessor/c.like


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef


XPT head hint=-----------------------------
--------------------------------------------------
----            `headName~
--------------------------------------------------

XPT class hint=class\ ..\ where..
class `context...{{~(`ctxt~) => `}}~`className~ `types~a~ where
    `ar~ :: `type~ `...~
    `methodName~ :: `methodType~`...~
`cursor~

XPT classcom hint=--\ |\ class..
-- | `classDescr~
class `context...{{~(`ctxt~) => `}}~`className~ `types~a~ where
    -- | `methodDescr~
    `ar~ :: `type~ `...~
    -- | `method_Descr~
    `methodName~ :: `methodType~`...~
`cursor~

XPT datasum hint=data\ ..\ =\ ..|..|..
data `context...{{~(`ctxt~) => `}}~`typename~`typeParams~ ~=
    `Constructor~ `ctorParams~VOID()~`
  `...~
    | `Ctor~ `params~VOID()~
    `...~
    `deriving...{{~deriving (`Eq,Show~)`}}~
`cursor~


XPT datasumcom hint=--\ |\ data\ ..\ =\ ..|..|..
-- | `typeDescr~VOID()~
data `context...{{~(`ctxt~) => `}}~`typename~` `typeParams~ ~=
    -- | `ConstructorDescr~
    `Constructor~ `ctorParams~VOID()~`
    `...~
    -- | `Ctor descr~VOID()~
    | `Ctor~ `params~VOID()~`
    `...~
    `deriving...{{~deriving (`Eq,Show~)`}}~
`cursor~

XPT parser hint=..\ =\ ..\ <|>\ ..\ <|>\ ..\ <?>
`funName~ = `rule~`
        `another_rule...{{~
        <|> `rule~`
        `more...{{~
        <|> `rule~`
        `more...~`}}~`}}~
        `err...{{~<?> "`descr~"`}}~
`cursor~

XPT datarecord hint=data\ ..\ ={}
data `context...{{~(`ctxt~) => `}}~`typename~`typeParams~ ~=
    `Constructor~ {
        `field~ :: `type~`
        `...{{~,
        `fieldn~ :: `typen~`
        `...~`}}~
    }
    `deriving...{{~deriving (`Eq, Show~)`}}~
`cursor~

XPT datarecordcom hint=--\ |\ data\ ..\ ={}
-- | `typeDescr~
data `context...{{~(`ctxt~) => `}}~`typename~`typeParams~ ~=
    `Constructor~ {
        `field~ :: `type~ -- ^ `fieldDescr~`
        `...{{~,
        `fieldn~ :: `typen~ -- ^ `fielddescr~`
        `...~`}}~
    }
    `deriving...{{~deriving (`Eq,Show~)`}}~
`cursor~

XPT instance hint=instance\ ..\ ..\ where
instance `className~ `instanceTypes~ where
    `methodName~ `~ = `decl~ `...~
    `method~ `~ = `declaration~`...~
`cursor~

XPT if hint=if\ ..\ then\ ..\ else
if `expr~
    then `thenCode~
    else `cursor~

XPT fun hint=fun\ pat\ =\ ..
`funName~ `pattern~ = `def~`
`...{{~
`name~R("funName")~ `pattern~ = `def~`
`...~`}}~

XPT funcom hint=--\ |\ fun\ pat\ =\ ..
-- | `function_description~
`funName~ :: `type~
`name~R("funName")~ `pattern~ = `def~`
`...{{~
`name~R("funName")~ `pattern~ = `def~`
`...~`}}~

XPT funtype hint=..\ ::\ ..\ =>\ ..\ ->\ .. ->
`funName~ :: `context...{{~(`ctxt~)
        =>`}}~ `type~ -- ^ `is~`
        `...{{~
        -> `type~ -- ^ `is~`
        `...~`}}~

XPT options hint={-#\ OPTIONS_GHC\ ..\ #-}
{-# OPTIONS_GHC `options~ #-}

XPT lang hint={-#\ LANGUAGE\ ..\ #-}
{-# LANGUAGE `langName~ #-}

XPT inline hint={-#\ INLINE\ ..\ #-}
{-# INLINE `phase...{{~[`2~] `}}~`funName~ #-}

XPT noninline hint={-#\ NOINLINE\ ..\ #-}
{-# NOINLINE `funName~ #-}

XPT type hint=..\ ->\ ..\ ->....
`context...{{~(`ctxt~) => `}}~`t1~ -> `t2~`...~ -> `t3~`...~

XPT deriving hint=deriving\ (...)
deriving (`classname~`...~,`classname~`...~)

XPT derivingstand hint=deriving\ instance\ ...
deriving instance `context...{{~`ctxt~ => `}}~`class~ `type~

XPT module hint=module\ ..\ ()\ where ...
XSET moduleName=S(S(E('%:r'),'^.','\u&', ''), '[\\/]\(.\)', '.\u\1', 'g')
module `moduleName~ `exports...{{~( `cursor~
    ) `}}~where

