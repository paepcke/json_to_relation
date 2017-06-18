'''
Created on Jun 16, 2017



@author: paepcke
'''
import glob
import os
import tempfile

# ------------------------- Public Function ------------

def collectFiles(root_dir, extension='gz', skip_non_readable=False):
    '''
    Return list of files in all subdirectories of
    root_dir if their extension is the value of
    parameter 'extension'. If skip_non_readable
    is True, only files readable by the current
    process are included. 
    
    If root_dir is a file, that file is returned as a
    string.
    
    Parameter root_dir may be a Unix shell glob, such 
    as '/tmp/myDir/*', '/tmp/myDir/Test[0-9].gz' or
    as '/tmp/myDir/*', '/tmp/myDir/Test[0-9][_F].gz'.
    
    A leading tilde is expanded to the current user's
    home directory.
    
    @param root_dir: directory in which to start search for files, or file. 
    @type root_dir: str
    @param extension: file extension that matching files must have
    @type extension: string
    @param skip_non_readable: where to include non-readable files
    @type skip_non_readable: bool
    @return: list of found files
    @rtype: list
    @raise ValueError: when root_dir or extensions are not strings. 
    '''
        
    if type(extension) != str:
        raise ValueError('Extension must be a string, was: %s' % str(extension))
    if type(root_dir) != str:
        raise ValueError('Root directory must be a string, was: %s' % str(root_dir))
    
    # Normalize the extension: remove leading dot:
    if extension[0] == '.':
        extension = extension[1:]    
    
    # Resolve leading tilde:
    if root_dir[0] == '~':
        root_dir = os.path.expanduser(root_dir)
    
    # Expand wildcards and other globs, such as [0-9]:
    top_level = glob.glob(root_dir)    
    res = []
    
    # If glob expanded, we may have multiple
    # top starting points. If root_dir did
    # not have glob chars, we now have a 
    # singleton list: [root_dir]. Go through
    # each of these top level dirs/files, and
    # concatenate into one list:
    
    for top_file_or_dir in top_level:
        one_file_or_filelist = collectFilesHelper(top_file_or_dir, extension, skip_non_readable)
        
        # If return is a list, fuse it with the 
        # growing result. Else result is a 
        # string, which we append:
        
        if type(one_file_or_filelist) == str:
            res.append(one_file_or_filelist)
        else:
            res.extend(one_file_or_filelist)
    # Returns may include empty lists, such as
    #   ['foo/bar.gz', [],[]]. Eliminate those.
    
    clean_res = [file_list for file_list in res 
                    if len(file_list) > 0 or type(file_list) == str
                    ]
    return clean_res

# ------------------------- Private Function ------------

def collectFilesHelper(logFilesOrDirs, extension='gz', skip_non_readable=False, files_done=None):
    
    if os.path.isfile(logFilesOrDirs):
        # Eliminate non-readable results, if requested:
        if not os.access(logFilesOrDirs, os.R_OK) and skip_non_readable:
            return []

        # Correct extension?
        if os.path.splitext(logFilesOrDirs)[1] == '.' + extension:
            return logFilesOrDirs
        
        # Unwanted extension ==> unwanted file:
        return []
    
    # If it's not a directory at this point, it could
    # be a Unix special file that neither a file
    # not a directory to Python:
    
    if not os.path.isdir(logFilesOrDirs):
        return []

    # Keep track of examined files to avoid
    # duplicates:
    
    if files_done is None:
        files_done = []

    # Collection list:
    files_in_subtrees = []

    # Recursively walk the given directory:
    for (dirname, dirnames, filenames) in os.walk(logFilesOrDirs):

        # First, go depth-first into the directories
        # that were found:        
        for subdirname in dirnames:
            file_or_dir_list = collectFilesHelper(os.path.join(dirname, subdirname), 
                                                        extension, 
                                                        skip_non_readable,
                                                        files_done)
            if len(file_or_dir_list) > 0:
                files_in_subtrees.extend(file_or_dir_list)

        # Now files at this level:
        files_in_subtrees.extend([collectFilesHelper(os.path.join(dirname,file_this_level),
                                                     extension,
                                                     skip_non_readable,
                                                     files_done) 
                                 for file_this_level in filenames if file_this_level not in files_done])
        files_done.extend(filenames)
        
    return files_in_subtrees


if __name__ == '__main__':
    
    # Unit tests
    
    # Create under /tmp:
    #   f1 /tmp/TestDir1/dir1Test1.gz              rw,r,r
    #   f2 /tmp/TestDir1/dir1Test2.txt             rw,r,r
    #   f3 /tmp/TestDir1/TestDir2/dir2Test3.gz     w
    #   f4 /tmp/TestDir1/TestDir2/dir2Test4.txt    w
    #   f5 /tmp/TestDir1/TestDir2/dir2Test5.gz     rw,r,r
        
    dir1 = tempfile.mkdtemp(prefix='TestDir1', dir='/tmp')
    dir2 = tempfile.mkdtemp(prefix='TestDir2', dir=dir1)
    f1   = tempfile.NamedTemporaryFile(suffix='.gz', prefix='dir1Test1_', dir=dir1)
    f2   = tempfile.NamedTemporaryFile(suffix='.txt', prefix='dir1Test2_', dir=dir1)
    f3   = tempfile.NamedTemporaryFile(suffix='.gz', prefix='dir2Test3_', dir=dir2)
    f4   = tempfile.NamedTemporaryFile(suffix='.txt', prefix='dir2Test4_', dir=dir2)
    f5   = tempfile.NamedTemporaryFile(suffix='.gz', prefix='dir2Test5_', dir=dir2)
    f6   = tempfile.NamedTemporaryFile(suffix='.gz', prefix='homeTest6_', dir=os.environ['HOME'])    
    
    os.chmod(dir1, 0o775)
    os.chmod(dir2, 0o775)
    os.chmod(f1.name, 0o644)
    os.chmod(f2.name, 0o644)
    os.chmod(f3.name, 0o200)
    os.chmod(f4.name, 0o200)
    os.chmod(f5.name, 0o644)
    os.chmod(f6.name, 0o644)
    
    res = collectFiles(dir1, 'gz', skip_non_readable=True)
    assert(f1.name in res and f5.name in res and len(res) == 2)
     
    res = collectFiles(dir1, 'gz', skip_non_readable=False)
    assert(f1.name in res and f5.name in res and f3.name in res and len(res) == 3)
    
    res = collectFiles(os.path.join(dir1,dir2,'*'), 'gz', skip_non_readable=True)
    assert(f5.name in res and len(res) == 1)
    
    # Complex glob to match *Test<number>*:
    res = collectFiles(os.path.join(dir1,dir2,'*[0-9]_*'), 'gz', skip_non_readable=False)
    assert(f3.name in res and f5.name in res and len(res) == 2)
    
    # *Test<number><either _ or F>*:
    res = collectFiles(os.path.join(dir1,dir2,'*[0-9][_F]*'), 'gz', skip_non_readable=False)
    assert(f3.name in res and f5.name in res and len(res) == 2)

    # User home dir expansion ~/foo.gz:
    res = collectFiles(os.path.join('~','homeTest6_*'), 'gz', skip_non_readable=True)
    assert(f6.name in res and len(res) == 1)

    # Extension with leading period (ok to do):
    res = collectFiles(dir1, '.gz', skip_non_readable=True)
    assert(f1.name in res and f5.name in res and len(res) == 2)

    
    # Bad directory:
    try:
        res = collectFiles(None, 'gz', skip_non_readable=True)
        raise AssertionError("Expected exception for None as root_dir")
    except ValueError:
        pass

    # Bad extension:
    try:
        res = collectFiles(dir1, None, skip_non_readable=True)
        raise AssertionError("Expected exception for None as extension")
    except ValueError:
        pass


    print('All tests passed.')
    
