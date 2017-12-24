#include <windows.h>
#include "stdio.h"

bool wstrcmpl(WCHAR* s1, WCHAR* s2, int len)
{
	for (int i=0; i<len; i++)
	{
		if (s1[i] != s2[i])
		{
			return false;
		}
	}
	return true;
}
bool spliteq(WCHAR* src, WCHAR** key, WCHAR** val, WCHAR* buf)
{
	int i=0;
	bool eq=true;
	*key = &buf[2];
	for (int i=2; src[i]; i++) {
		buf[i]  = src[i];
		if (eq)
		{
			if (buf[i] == L'=')
			{
				buf[i]=L'\0';
				*val = &buf[i+1];
				eq == false;
			}
		}
	}
	return true;
}

int APIENTRY WinMain(HINSTANCE hInstance, 
		HINSTANCE hPrevInstance,
		LPSTR lpCmdLine,
		int nCmdShow)
{
	STARTUPINFOW si;
	PROCESS_INFORMATION pi;

	int argc;
	WCHAR** argv;
	argv = CommandLineToArgvW(GetCommandLineW(), &argc);
	if (!argv) {
		::OutputDebugStr("not get arg\n");
		return -1;
	}

	for (int i=1; i<argc-1; i++)
	{

		if (wstrcmpl(argv[i], L"-d", 2))
		{
			WCHAR* dir=argv[i];
			dir = &dir[2];
			if (!SetCurrentDirectoryW(dir))
			{
				::OutputDebugStringW(L"err cd\n");
			}
			{
			WCHAR buf[256];
			_snwprintf(buf, 256, L"%2d: cd %s\n", i, argv[i]);
			::OutputDebugStringW(buf);
			}
		}
		else if (wstrcmpl(argv[i], L"-e", 2))
		{
			WCHAR buf[1024];
			WCHAR *key,*val;
			spliteq(argv[i], &key, &val, buf);
			SetEnvironmentVariableW(key, val);
			{
			WCHAR buf[256];
			_snwprintf(buf, 256, L"%2d: env %s\n", i, argv[i]);
			::OutputDebugStringW(buf);
			}
		}
	}
	

	ZeroMemory(&si, sizeof(si));
	si.cb = sizeof(si);
	ZeroMemory(&pi, sizeof(pi));

	if (! CreateProcessW(NULL,
		argv[argc-1],
		NULL,
		NULL,
		FALSE,
		0,
		NULL,
		NULL,
		&si,
		&pi)) {
		::OutputDebugStr("err create process\n");
			return -1;
	}
	CloseHandle(pi.hProcess);
	CloseHandle(pi.hThread);

	return 0;
}
