#ifndef RUNNER_OAUTH_CALLBACK_H_
#define RUNNER_OAUTH_CALLBACK_H_

#include <windows.h>

#include <string_view>

// Matches the WM_COPYDATA message used by the pinned app_links Windows plugin.
constexpr ULONG_PTR kOculumAppLinksMessage = WM_USER + 2;

bool RegisterOculumOAuthCallback(HWND window, std::string_view redirect);
void UnregisterOculumOAuthReceiver(HWND window);
bool IsOculumOAuthCallbackArgument(std::string_view uri);
bool ForwardOculumOAuthCallback(std::string_view uri);
bool IsOculumOAuthCallbackMessage(HWND window, const COPYDATASTRUCT& data);

#endif  // RUNNER_OAUTH_CALLBACK_H_
