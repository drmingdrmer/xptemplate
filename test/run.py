#!/usr/bin/env python
# coding: utf-8

import os
import sys
import time
import fnmatch
import Queue
import re

import lg
import tmux

from util import sh, fread, delay, _path, _thread

logger = None

flags = {
        'stdoutlvl': 'info',
        'nthread': 8,
}
test_root_path = os.path.dirname(os.path.realpath(__file__))

class TestError( Exception ): pass

key = {
        "cr":  "\r",
        "tab": "	",
        "esc": "",
        "c_v": "",
        "c_l": "",
        "c_c": "",
        "c_o": "",
}

def safe_elt(lst, i):
    if i >= len(lst):
        return None
    else:
        return lst[i]


def handle_test_err(sess, err):

    # with TestError, stop and see what happened
    test, failuretype, ex, ac = err[0:4]
    case_name = test['case_name']
    testname = test['name']
    vimarg = test['vimarg']

    mes = "failure: {tp}: {case} {name} {arg}".format(
            case=case_name, name=testname,
            tp=failuretype, arg=vimarg)

    reason = []
    for i in range( len(ex) ):
        if i >= len(ac) or ex[i] != ac[i]:
            reason.append("{ln} {expected} {actual}".format(
                    ln=i+1,
                    expected=safe_elt(ex, i),
                    actual=safe_elt(ac, i)))
    reason.append("screen:")
    reason.append(test["screen_captured"])
    reason = "\n".join(reason)

    sess['failures'].append((mes, reason))

    test['logger'].info(mes)
    test['logger'].info(reason)

def main( pattern, subpattern='*' ):

    logger.info("test: {0} {1}".format(pattern, subpattern))
    sess = {
            'q': Queue.Queue(1024),
            'passed':[],
            'failures': [],
    }

    case_root = os.path.join( test_root_path, "cases" )

    cases = os.listdir( case_root )
    cases.sort()

    cs = []
    for c in cases:
        if not os.path.isdir( os.path.join( case_root, c ) ):
            continue

        if fnmatch.fnmatch( c, pattern ):
            cs.append((sess, c, subpattern))
            logger.info("to test: " + c)

    for what in cs:
        sess['q'].put(what)

    ths = []
    for ii in range(flags['nthread']):
        ths.append(_thread(case_runner_safe, [sess]))

    for th in ths:

        while th.is_alive():

            time.sleep(1)

            for f in sess['failures']:
                logger.info(f[0])

        th.join()

    if len(sess['failures']) == 0:
        logger.info("all test passed")
        return

    logger.info("failures:")
    for f in sess['failures']:
        mes, reason = f
        logger.info(mes)
        logger.info(reason)

def case_runner_safe(sess):

    try:
        case_runner(sess)
    except Exception as e:
        logger.exception(repr(e))

def case_runner(sess):

    while True:
        try:
            args = sess['q'].get(block=False)
        except Queue.Empty:
            break
        run_case(*args)

def run_case(sess, casename, subpattern):
    try:
        _run_case(sess, casename, subpattern)
        return
    except TestError as e:
        handle_test_err(sess, e)

    except Exception as e:
        logger.exception(repr(e))

    # if flags[ 'keep' ]:
    #     # wait for user to see what happened
    #     logger.info( "Ctrl-c to quit" )
    #     while True:
    #         time.sleep( 10 )

def _run_case( sess, cname, subpattern ):

    logger.debug( " start: " + cname + " ..." )

    case_path = _path( test_root_path, "cases", cname )
    case_tests_dir = _path(case_path, 'tests')
    testnames = os.listdir(case_tests_dir)

    testnames = [x for x in testnames
                 if fnmatch.fnmatch( x, subpattern )]

    for testname in testnames:

        test = load_test(cname, case_path, testname)
        if test[None][:1] == ['TODO']:
            test['logger'].info("SKIP: " + testname)
            continue

        t = test.copy()
        run_case_test(t)

    logger.info("case passed: " + cname)

def run_case_test(test):

    test['logger'].debug("  case: {0} {1} {2}".format(
            test['case_name'], test['name'], test['vimarg'],
    ))

    case_path = test['case_path']
    tm = tmux.Tmux(test['sess_name'])
    test['tmux'] = tm

    tm.try_kill()

    start_cmd = vim_start_cmdstring(test)
    tm.start(start_cmd)
    delay()
    test['logger'].debug( "vim started with: " + repr(start_cmd) )

    assert_no_err_on_screen(test)

    vim_add_rtp(test)
    vim_set_default_ft(test)
    vim_so_fn( test, _path(case_path, "setting.vim") )

    vim_add_settings(test, test['setting'])
    vim_add_local_settings(test, test['localsetting'])
    vim_add_cmd(test, test['cmd'])
    delay()

    _dump(test)
    test['tmux'].sendkeys('i')
    vim_key_sequence_strings(test)
    find_screen_text_matching(test)

    rst = vim_dump_file_content(test)

    _check_rst(test, rst )

    test['logger'].info("ok: {0} {1} {2}".format(
            test['case_name'], test['name'], test['vimarg'],
    ))
    tm.kill()


def load_test(case_name, case_path, testname):

    test_path = _path(case_path, "tests", testname)

    sess_name = 'xpt-test_{0}_{1}'.format(case_name, testname)

    # None for internal parameters
    test = { None: [],
             'case_name': case_name,
             'case_path': case_path,
             'name': testname,
             'sess_name': sess_name,
             'logger': lg.make_logger(case_name, stdoutlvl=flags['stdoutlvl']),

             'vimarg': [],
             'pre_vimrc': [],
             'setting': [],
             'localsetting': [],
             'cmd': [],
             'keys': [],
             'expected': [],
             'screen_captured': None,
             'screen': [],
             'screen_matched': [],
    }

    cont = fread(test_path)
    state = None
    for line in cont.split('\n'):

        if line == '':
            state = None
            continue

        if state is None and line[:-1] in test:
            state = line[:-1]
            if state == 'map':
                state = 'cmd'
            continue

        if line == 'emptyline':
            line = ''

        test[state].append( line )
        test['logger'].debug( '- ' + repr(state) + ': ' + repr(line) )

    test['expected'] = '\n'.join(test['expected'])
    return test

def vim_start_cmdstring(test):
    vimrcfn = _path( test['case_path'], "vimrc" )
    if not os.path.exists( vimrcfn ):
        vimrcfn = _path( test_root_path, "core_vimrc" )

    pre_vimrc_cmds = test['pre_vimrc']

    cmds = [ 'vim', '-u', vimrcfn, ]
    cmds += test['vimarg']
    for c in pre_vimrc_cmds:
        cmds += [ '--cmd', "'"+c.replace("'", "\"'\"")+"'" ]

    return ' '.join(cmds)

def vim_so_fn(test, fn):
    if not os.path.exists( fn ):
        return

    test['tmux'].sendkeys( ":so " + fn, key['cr'] )
    delay()
    test['logger'].debug( "vim setting loaed: " + repr(fn) )

def vim_add_rtp( test ):
    case_path = test['case_path']
    if not os.path.exists( case_path ):
        return

    test['tmux'].sendkeys( ":set rtp+=", case_path, key['cr'] )
    logger.debug( "additional rtp: " + repr( case_path ) )

def vim_add_settings( test, settings ):
    if len( settings ) == 0:
        return
    vim_cmd( test, [ "set" ] + settings )

def vim_add_local_settings( test, settings ):
    if len( settings ) == 0:
        return
    vim_cmd( test, [ "setlocal" ] + settings )

def vim_add_cmd(test, cmds):
    for cmd in cmds:
        vim_cmd(test, [cmd])

def vim_cmd( test, elts ):
    s = ":" + ' '.join( elts )
    test['tmux'].sendkeys( s + key['cr'] )
    logger.debug( s )

def vim_set_default_ft(test):
    case_path = test['case_path']
    ft_foo_path = _path( case_path, 'ftplugin', 'foo', 'foo.xpt.vim' )
    logger.debug( "ft_foo_path: " + ft_foo_path )
    if os.path.isfile( ft_foo_path ):
        vim_add_settings( test, [ 'filetype=foo' ] )
        # changing setting may cause a lot ftplugin to load
        delay()

def vim_key_sequence_strings( test ):

    lines = test['keys']

    for line in lines:
        if line == '':
            continue
        test['logger'].debug("send keys: " + repr(line))
        test['tmux'].sendkeys(line)
        delay()
        _dump(test)
        assert_no_err_on_screen(test)

    logger.debug( "end of key sequence" )

def vim_dump_file_content( test ):

    fn = _path(test['case_path'], 'rst')

    test['tmux'].sendkeys( key['esc']*4 )
    delay()
    test['tmux'].sendkeys( ":w " + fn, key['cr'] )

    now = time.time()
    while time.time() < now + 5 and not os.path.exists( os.path.join( fn ) ):
        time.sleep(0.2)

    logger.debug( "load file content from " + repr(fn))

    rst = fread(fn)
    if rst is not None:
        os.unlink( fn )

    return rst

def find_screen_text_matching(test):
    screen = test['tmux'].capture()
    test['screen_captured'] = screen

    for reg in test['screen']:
        if reg in test['screen_matched']:
            continue
        if re.findall(reg, screen, flags=re.DOTALL):
            test['screen_matched'].append(reg)

def assert_no_err_on_screen(test):

    screen = test['tmux'].capture()
    test['screen_captured'] = screen

    lines = screen.split("\n")
    lines = [x for x in lines if x not in ('', )]

    err_patterns = (
            'Error',
            '^E[0-9]{1,3}:',
    )

    for ptn in err_patterns:
        err_found = re.findall(ptn, screen)
        if len(err_found) > 0:
            raise TestError( test, 'error_occur', err_found, [''] )

def _check_rst(test, rst):

    expected = test['expected']

    if expected != rst:
        raise TestError( test, 'result_unmatched', expected.split("\n"), rst.split("\n") )

    test['screen'].sort()
    test['screen_matched'].sort()
    if test['screen'] != test['screen_matched']:
        raise TestError( test, 'screen_unmatched', test['screen'], test['screen_matched'] )

def _dump(test):
    screen = test['tmux'].capture()
    lines = screen.split("\n")
    lines = [ test['case_name'] + '_' + test['name'] + '  |' + x for x in lines]
    screen = "\n".join(lines)

    test['logger'].debug("\n"+screen)


if __name__ == "__main__":
    args = sys.argv
    if '-v' in args:
        flags[ 'stdoutlvl' ] = 'debug'
        args.remove( '-v' )

    # concurrent
    if '-c' in args:
        i = args.index('-c')
        flags[ 'nthread' ] = int(args[i+1])
        args.pop( i )
        args.pop( i )

    logger = lg.make_logger('xpt-test', stdoutlvl=flags['stdoutlvl'])

    if len(args) > 1:
        main(*args[1:])
    else:
        main("*")
