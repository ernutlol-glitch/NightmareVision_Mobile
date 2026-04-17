package funkin.utils;

import haxe.io.Bytes as HaxeBytes;

import lime.ui.FileDialog;
import lime.utils.Bytes;

import openfl.utils.ByteArray;
import openfl.net.FileFilter;
import openfl.filesystem.File;

typedef BrowseOptions =
{
	var ?typeFilter:Array<FileFilter>;
	var ?title:String;
	var ?defaultSearch:String;
}

/**
 * Utility class to make browsing and saving files a little bit more convenient
 */
@:nullSafety
class FileUtil
{
	public static function browseForFile(options:BrowseOptions, ?onSelect:String->Void, ?onCancel:Void->Void)
	{
		final title = options.title;
		final filters = options.typeFilter;
		final startPath = options.defaultSearch;
		
		FileDialog.openFile(FlxG.stage.window, title, (files, filter) -> {
			if (files != null && files.length > 0)
			{
				if (onSelect != null) onSelect(fixAndroidPath(files[0]));
			}
			else
			{
				if (onCancel != null) onCancel();
			}
		}, @:privateAccess @:nullSafety(Off) File.__getFilterTypes(filters), startPath);
	}
	
	public static function browseForMultipleFiles(options:BrowseOptions, ?onSelect:Array<String>->Void, ?onCancel:Void->Void)
	{
		final title = options.title;
		final filters = options.typeFilter;
		final startPath = options.defaultSearch;
		
		FileDialog.openFile(FlxG.stage.window, title, (files, filter) -> {
			if (files != null && files.length > 0)
			{
				if (onSelect != null)
                {
                    var fixed = [];
                    for (f in files) fixed.push(fixAndroidPath(f));
                    onSelect(fixed);
                }
			}
			else
			{
				if (onCancel != null) onCancel();
			}
		}, @:privateAccess @:nullSafety(Off) File.__getFilterTypes(filters), startPath, true);
	}
	
	public static function saveFile(data:Dynamic, ?fileName:String, ?onSelect:String->Void, ?onCancel:Void->Void)
	{
		if (data == null) return;
		
		var filters = null;
		if (fileName != null && fileName.extension().length > 0)
		{
			final ext:String = fileName.extension();
			filters = [new lime.ui.FileDialogFilter('*.$ext', ext)];
		}
		
		FileDialog.saveFile(FlxG.stage.window, 'Save', (file, filter) -> {
			if (file != null && file.length > 0)
			{
				Bytes.toFile(file, dynamicToBytes(data));
				
				if (onSelect != null) onSelect(file);
			}
			else
			{
				if (onCancel != null) onCancel();
			}
		}, filters, fileName);
	}

    static function fixAndroidPath(path:String):String
    {
        if (path == null) return path;

        if (path.startsWith("content://"))
        {
            var bytes = null;

            try {
                bytes = lime.utils.Bytes.fromFile(path);
            } catch (e) {
                trace("Error reading URI: " + e);
            }

            if (bytes == null)
                return path; 

            var out = StorageUtil.getStorageDirectory()
            + "/cache_" + haxe.crypto.Md5.encode(path) + ".json";

            sys.io.File.saveBytes(out, bytes);
            return out;
            }

        return path;
    }
                                 
	public static function saveFileToPath(data:Dynamic, path:String, ensureDirectory:Bool = true):Bool
	{
		try
		{
			if (ensureDirectory && path.directory() != '' && !FunkinAssets.isDirectory(path.directory()))
			{
				FileSystem.createDirectory(path.directory());
			}
			
			Bytes.toFile(path, dynamicToBytes(data));
			return true;
		}
		catch (e)
		{
			Logger.log('Failed to save to $path\nException: $e', ERROR);
			return false;
		}
	}
	
	static function dynamicToBytes(input:Dynamic):Bytes
	{
		if (input is ByteArrayData || input is HaxeBytes) return input;
		
		final bytes = new ByteArray();
		bytes.writeUTFBytes(Std.string(input));
		
		return bytes;
	}
}
