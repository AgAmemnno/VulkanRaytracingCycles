#include "pch.h"
#include "global.hpp"
#ifndef _WIN32
#ifdef __APPLE__
#include <sys/time.h>
#else
#define _XOPEN_SOURCE 700
#include <time.h>
#endif
#endif






int killme = 0;
int sys_width = 1980;	/* dimensions of default screen */
int sys_height = 1200;
float sys_dpi = 1.0;
int vid_width = 1280;	/* dimensions of our part of the screen */
int vid_height = 720;
int mouse_x = 0;
int mouse_y = 0;
int mickey_x = 0;
int mickey_y = 0;
char mouse[8] = { 0,0,0,0,0,0,0,0 };
char keys[KEYMAX];


///////////////////////////////////////////////////////////////////////////////
//////// sys_time = ticks since app start, where 1s = sys_ticksecond of ticks
///////////////////////////////////////////////////////////////////////////////
#ifdef _WIN32

uint64_t sys_ticksecond = 1000;
static uint64_t sys_time_start = 0;
uint64_t sys_time(void)
{
	uint64_t now;
	QueryPerformanceCounter((LARGE_INTEGER*)&now);
	return now - sys_time_start;
}

void sys_time_init(void)
{
	QueryPerformanceFrequency((LARGE_INTEGER*)&sys_ticksecond);
	QueryPerformanceCounter((LARGE_INTEGER*)&sys_time_start);
}

#else	// Mac & Linux versions are identical


uint64_t sys_ticksecond = 1000000000;
static uint64_t sys_time_start = 0;
uint64_t sys_time(void)
{
	struct timespec ts;
	clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
	return ((uint64_t)ts.tv_sec * 1000000000 + ts.tv_nsec) - sys_time_start;
}

void sys_time_init(void)
{
	struct timespec ts;
	clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
	sys_time_start = (uint64_t)ts.tv_sec * 1000000000 + ts.tv_nsec;
}
#endif

///////////////////////////////////////////////////////////////////////////////
//////// sys_browser(url) - opens a webbrowser at the given url
///////////////////////////////////////////////////////////////////////////////

#ifdef _WIN32
void sys_browser(wchar_t* url)
{

	//ShellExecute(NULL, L"open", url, NULL, NULL, SW_SHOWNORMAL);
}

#elif defined __APPLE__
#include <objc/objc.h>
#include <objc/runtime.h>
#include <objc/message.h>
void sys_browser(char* url)
{
	//	NSURL *MyNSURL = [NSURL URLWithString:[NSString stringWithUTF8String:url]];
	//	[[NSWorkspace sharedWorkspace] openURL:MyNSURL];
	SEL URLWithString = sel_registerName("URLWithString:");
	SEL stringWithUTF8String = sel_registerName("stringWithUTF8String:");
	SEL sharedWorkspace = sel_registerName("sharedWorkspace");
	SEL openURL = sel_registerName("openURL:");
	Class NSURL = objc_getClass("NSURL");
	Class NSString = objc_getClass("NSString");
	Class NSWorkspace = objc_getClass("NSWorkspace");
	id url_nsstring = ((id(*)(Class, SEL, char*))objc_msgSend)(NSString, stringWithUTF8String, url);
	id ns_url = ((id(*)(Class, SEL, id))objc_msgSend)(NSURL, URLWithString, url_nsstring);
	id workspace = ((id(*)(Class, SEL))objc_msgSend)(NSWorkspace, sharedWorkspace);
	((id(*)(id, SEL, id))objc_msgSend)(workspace, openURL, ns_url);
}

#else	// linux version
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
void sys_browser(char* url)
{
	int c = 1000;
	char buf[c];
	memset(buf, 0, sizeof(char) * c);
	snprintf(buf, c, "sensible-browser %s &", url);
	system(buf);
}
#endif

/*

#define SYS_EVENT_MAX 256
struct sys_event sys_events[SYS_EVENT_MAX];
uint32_t sys_event_in = 0;
uint32_t sys_event_out = 0;

void sys_event_init(void)
{
	sys_event_in = 0;
	sys_event_out = 0;
}

int sys_event_read(struct sys_event* event)
{
	if (sys_event_in == sys_event_out)return 0;

	sys_event_out++;
	if (sys_event_out == SYS_EVENT_MAX)
	{
		sys_event_out = 0;
	}
	*event = sys_events[sys_event_out];
	return 1;
}

int sys_event_write(struct sys_event event)
{
	if (sys_event_in == (sys_event_out - 1)) return 0;

	if ((sys_event_in == (SYS_EVENT_MAX - 1)) &&
		sys_event_out == 0) return 0;

	sys_event_in++;
	if (sys_event_in == SYS_EVENT_MAX)
	{
		sys_event_in = 0;
	}

	sys_events[sys_event_in] = event;
	return 1;
}

*/

/*

uint16_t sys_key_modifiers(void)
{
	uint16_t modifiers = 0;
	if (keys[KEY_LSHIFT]) {
		modifiers |= (KEY_MOD_SHIFT | KEY_MOD_LSHIFT);
	}
	if (keys[KEY_RSHIFT]) {
		modifiers |= (KEY_MOD_SHIFT | KEY_MOD_RSHIFT);
	}
	if (keys[KEY_LALT]) {
		modifiers |= (KEY_MOD_ALT | KEY_MOD_LALT);
	}
	if (keys[KEY_RALT]) {
		modifiers |= (KEY_MOD_ALT | KEY_MOD_RALT);
	}
	if (keys[KEY_LCONTROL]) {
		modifiers |= (KEY_MOD_CTRL | KEY_MOD_LCTRL);
	}
	if (keys[KEY_RCONTROL]) {
		modifiers |= (KEY_MOD_CTRL | KEY_MOD_RCTRL);
	}
	if (keys[KEY_LLOGO]) {
		modifiers |= (KEY_MOD_LOGO | KEY_MOD_LLOGO);
	}
	if (keys[KEY_RLOGO]) {
		modifiers |= (KEY_MOD_LOGO | KEY_MOD_RLOGO);
	}
	if (keys[KEY_MENU]) {
		modifiers |= KEY_MOD_MENU;
	}
	return modifiers;
}

*/
