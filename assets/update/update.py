"""Verified GitHub package installer. Receives only locally generated JSON paths."""
import json, os, pathlib, shutil, stat, subprocess, sys, tarfile, time, zipfile
c=json.loads(pathlib.Path(sys.argv[1]).read_text())
work=pathlib.Path(c['work']).resolve()
exe=pathlib.Path(c['executable']).resolve()
unpack=work/'unpacked'
backup=work/'previous-runtime'
moved=[]
installed=[]
def child(path,root):
    p=path.resolve()
    if p==root.resolve() or root.resolve() not in p.parents: raise ValueError('Unsafe archive path')
    if path.is_symlink(): raise ValueError('Linked runtime is unsupported')
    return p
def extract_zip(path,dest):
    with zipfile.ZipFile(path) as z:
        for info in z.infolist():
            child(dest/info.filename,dest)
            if stat.S_ISLNK(info.external_attr >> 16): raise ValueError('Archive link')
        z.extractall(dest)
try:
    unpack.mkdir()
    extract_zip(c['archive'],unpack)
    if c['platform']=='macos':
        apps=list(unpack.rglob('*.app'))
        if not apps:
            nested=list(unpack.rglob('*.zip'))
            if len(nested)!=1: raise ValueError('Ambiguous macOS package')
            # ditto preserves the signed bundle metadata; validated package paths first.
            with zipfile.ZipFile(nested[0]) as z:
                for i in z.infolist(): child(unpack/'bundle'/i.filename,unpack/'bundle')
            subprocess.run(['ditto','-x','-k',str(nested[0]),str(unpack/'bundle')],check=True)
            apps=list((unpack/'bundle').glob('*.app'))
        if len(apps)!=1: raise ValueError('Expected one application bundle')
        source=apps[0]
        target=next((p for p in exe.parents if p.suffix=='.app'),None)
        if target is None or target.is_symlink(): raise ValueError('Installed application bundle is unavailable')
        entries=[(source,target)]
    else:
        archives=list(unpack.rglob('*.tar.gz'))
        if len(archives)!=1: raise ValueError('Expected one Linux package')
        with tarfile.open(archives[0]) as t:
            for m in t.getmembers():
                child(unpack/'bundle'/m.name,unpack/'bundle')
                if not (m.isfile() or m.isdir()): raise ValueError('Unsupported archive member')
            t.extractall(unpack/'bundle',filter='data')
        sources=list((unpack/'bundle').rglob('oculum'))
        sources=[p for p in sources if p.is_file()]
        if len(sources)!=1: raise ValueError('Expected one executable')
        source=sources[0].parent
        target=exe.parent
        entries=[(source/name,target/name) for name in ['oculum','lib','data']]
        if not all(s.exists() for s,_ in entries): raise ValueError('Incomplete Linux runtime')
    for _,dest in entries:
        if not os.access(dest.parent,os.W_OK): raise PermissionError('Install directory is not writable; use the downloaded package manually')
    for _ in range(120):
        try: os.kill(int(c['pid']),0)
        except ProcessLookupError: break
        time.sleep(1)
    else: raise TimeoutError('Oculum has not closed')
    backup.mkdir()
    for src,dest in entries:
        if dest.exists(): shutil.move(str(dest),str(backup/dest.name));moved.append(dest)
        installed.append(dest)
        if src.is_dir(): shutil.copytree(src,dest,symlinks=True)
        else: shutil.copy2(src,dest);dest.chmod(dest.stat().st_mode|0o111)
    subprocess.Popen(['open',str(target)] if c['platform']=='macos' else [str(exe)],start_new_session=True)
    (work/'result.txt').write_text('success')
except Exception as error:
    for dest in installed:
        if dest.is_dir(): shutil.rmtree(dest)
        elif dest.exists(): dest.unlink()
    for dest in moved: shutil.move(str(backup/dest.name),str(dest))
    (work/'error.txt').write_text(str(error))
    if exe.exists(): subprocess.Popen([str(exe)],start_new_session=True)
    raise
