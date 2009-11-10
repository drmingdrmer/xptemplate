" These snippets work only in html context of php file
if &filetype != 'php'
    finish
endif

XPTemplate priority=lang-2

XPTemplateDef


XPT shebang hint=#!/usr/bin/env\ php
#!/usr/bin/env php

..XPT

XPT sb alias=shebang


XPT php hint=<?$PHP_TAG\ ?>
<?`$PHP_TAG^ `cursor^ ?>

XPT pe hint=<?=\ ?>
<?=`cursor^?>

