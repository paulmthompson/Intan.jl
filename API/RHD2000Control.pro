QT += core

QT -= gui

TARGET = RHD2000Control

TEMPLATE = app
CONFIG += console
CONFIG -= app_bundle

SOURCES += main.cpp \
    okFrontPanelDLL.cpp \
    rhd2000evalboard.cpp \
    rhd2000registers.cpp \
    rhd2000datablock.cpp

HEADERS += \
    okFrontPanelDLL.h \
    rhd2000evalboard.h \
    rhd2000registers.h \
    rhd2000datablock.h

