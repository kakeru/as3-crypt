package  {
	import com.hurlant.crypto.symmetric.ICipher;
	import com.hurlant.crypto.symmetric.IPad;
	import com.hurlant.crypto.Crypto;
	import com.hurlant.crypto.symmetric.IVMode;
	import com.hurlant.util.Hex;
	import com.hurlant.crypto.symmetric.NullPad;
	import fl.controls.Button;
	import fl.controls.CheckBox;
	import fl.controls.RadioButton;
	import fl.controls.TextInput;
	import flash.accessibility.*;
	import flash.display.*;
	import flash.errors.*;
	import flash.events.*;
	import flash.external.*;
	import flash.filters.*;
	import flash.geom.*;
	import flash.media.*;
	import flash.net.*;
	import flash.printing.*;
	import flash.system.*;
	import flash.text.*;
	import flash.ui.*;
	import flash.utils.*;
	import flash.xml.*;
	import adobe.utils.*;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeDragManager;
	import flash.desktop.Clipboard;
	import flash.desktop.NativeDragManager;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	
	
	public class CryptFile extends MovieClip {
		public static const MODE_CRYPT:String = "modeCrypt";
		public static const MODE_ENCRYPT:String = "modeEncrypt";
		private var mode:String;
		
		public var headCheckBox:CheckBox;
		public var cryptbtn:Button;
		public var encryptbtn:Button;
		public var keyText:TextInput;
		public var ivText:TextInput;
		
		private var fr:FileReference;
		private var convertData:ByteArray;
		
		public function CryptFile() {
			cryptbtn.addEventListener(MouseEvent.CLICK, cryptSelect);
			encryptbtn.addEventListener(MouseEvent.CLICK, encryptSelect);
		}
		private function cryptSelect(evt:Event):void {
			mode = MODE_CRYPT;
			fr = new FileReference()
            fr.addEventListener(Event.SELECT, frSelect);
            fr.browse();
		}
		private function encryptSelect(evt:Event):void {
			mode = MODE_ENCRYPT;
			fr = new FileReference()
            fr.addEventListener(Event.SELECT, frSelect);
            fr.browse();
		}
        private function frSelect(evt:Event):void {
			fr.addEventListener(Event.COMPLETE, frLoadComplete);
			fr.load();
        }
		private function frLoadComplete(evt:Event):void {
			var crypt:ICipher = getCrypt();
			convertData = new ByteArray();
			
			var headSize:Number = Math.min(1024 * 100, fr.data.length);
			
			if (headCheckBox.selected) {
				convertData.writeBytes(fr.data, 0, headSize);
			} else {
				convertData.writeBytes(fr.data, 0, fr.data.length);
			}
			if (mode == MODE_CRYPT) {
				crypt.encrypt(convertData);
			} else {
				crypt.decrypt(convertData);
			}
			if (headCheckBox.selected && headSize < fr.data.length) {
				convertData.writeBytes(fr.data, headSize, fr.data.length - headSize);
			}
			var desktop:File = File.desktopDirectory;
			try {
				desktop.browseForSave("Save As");
				desktop.addEventListener(Event.SELECT, saveData);
			}
			catch (error:Error) {
				trace("Failed:", error.message);
			}
		}
		private function saveData(evt:Event):void {
			var newFile:File = evt.target as File;
			if (!newFile.exists) {
				var stream:FileStream = new FileStream();
				stream.open(newFile, FileMode.WRITE);
				stream.writeBytes(convertData, 0, convertData.length);
				stream.close();
			}
		}
		private function getCrypt(): ICipher {
			var pad:IPad = new NullPad();
			var key:ByteArray = Hex.toArray(Hex.fromString(keyText.text));
			var crypt:ICipher = Crypto.getCipher('blowfish-cbc', key, pad);
			
			pad.setBlockSize(crypt.getBlockSize());
			if (crypt is IVMode) {
				trace('IVMode');
				var ivmode:IVMode = crypt as IVMode;
				ivmode.IV = Hex.toArray(ivText.text);
			}
			return crypt;
		}
	}
}