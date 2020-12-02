/*
 * Copyright (c) 2012 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/libpd/libpd for documentation
 *
 * This file was adapted from the ofxPd openFrameworks addon example:
 * https://github.com/danomatika/ofxPd
 *
 */
#pragma once

#include "PdBase.hpp"
#include "lua.hpp"

#define NMSG  6
#define NMIDI 7

// custom receiver class
class PdObject : public pd::PdReceiver ,public pd::PdMidiReceiver {
public:

	static lua_State *L;

	// callback refs
	int fnprint ,fnbang ,fnfloat ,fnsymbol ,fnlist  ,fnmessage
	   ,fnnote  ,fnctrl ,fnprog  ,fnpitch  ,fnafter ,fnpoly  ,fnbyte;

	int *msgs[NMSG]   =
	{	&fnprint ,&fnbang ,&fnfloat ,&fnsymbol ,&fnlist  ,&fnmessage   };
	int *midis[NMIDI] =
	{	&fnnote  ,&fnctrl ,&fnprog  ,&fnpitch  ,&fnafter ,&fnpoly  ,&fnbyte   };

	void setFuncs();
	void setFunc(const char *name);

	PdObject(bool doSet=false) {
		for (int i=0; i<NMSG;  i++) *msgs[i]  = -1;
		for (int i=0; i<NMIDI; i++) *midis[i] = -1;
		if  (L && doSet) setFuncs();
	}

	// pd message receiver callbacks
	void print          (const std::string &message);
	void receiveBang    (const std::string &dest);
	void receiveFloat   (const std::string &dest ,float num);
	void receiveSymbol  (const std::string &dest ,const std::string &symbol);
	void receiveList    (const std::string &dest ,const pd::List &list);
	void receiveMessage (const std::string &dest ,const std::string &msg
		,const pd::List &list);

	// pd midi receiver callbacks
	void receiveNoteOn         (const int channel ,const int pitch ,const int velocity);
	void receiveControlChange  (const int channel ,const int controller ,const int value);
	void receiveProgramChange  (const int channel ,const int value);
	void receivePitchBend      (const int channel ,const int value);
	void receiveAftertouch     (const int channel ,const int value);
	void receivePolyAftertouch (const int channel ,const int pitch ,const int value);
	void receiveMidiByte       (const int port    ,const int byte);
};
