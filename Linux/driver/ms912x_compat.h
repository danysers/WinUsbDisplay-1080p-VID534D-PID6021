/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef MS912X_COMPAT_H
#define MS912X_COMPAT_H

/* Linux 6.8 (Ubuntu 24.04 GA) through current Ubuntu HWE headers. */
#ifndef MS912X_HAS_ATOMIC_COMMIT
#define drm_atomic_commit drm_atomic_state
#endif

#ifndef timer_container_of
#define timer_container_of(var, callback_timer, timer_field) \
	container_of(callback_timer, typeof(*var), timer_field)
#endif

#ifndef MS912X_HAS_TIMER_DELETE
#define timer_delete_sync del_timer_sync
#endif

#endif
