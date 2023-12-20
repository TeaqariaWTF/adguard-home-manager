// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:adguard_home_manager/widgets/options_menu.dart';

import 'package:adguard_home_manager/providers/status_provider.dart';
import 'package:adguard_home_manager/classes/process_modal.dart';
import 'package:adguard_home_manager/functions/snackbar.dart';
import 'package:adguard_home_manager/functions/copy_clipboard.dart';
import 'package:adguard_home_manager/models/menu_option.dart';
import 'package:adguard_home_manager/providers/app_config_provider.dart';
import 'package:adguard_home_manager/functions/get_filtered_status.dart';
import 'package:adguard_home_manager/models/logs.dart';
import 'package:adguard_home_manager/functions/format_time.dart';

class LogTile extends StatelessWidget {
  final Log log;
  final int length;
  final int index;
  final bool? isLogSelected;
  final void Function(Log) onLogTap;
  final bool? useAlwaysNormalTile;
  final bool twoColumns;

  const LogTile({
    super.key,
    required this.log,
    required this.length,
    required this.index,
    this.isLogSelected,
    required this.onLogTap,
    this.useAlwaysNormalTile,
    required this.twoColumns,
  });

  @override
  Widget build(BuildContext context) {
    final appConfigProvider = Provider.of<AppConfigProvider>(context);
    final statusProvider = Provider.of<StatusProvider>(context);

    Widget logStatusWidget({
      required IconData icon, 
      required Color color, 
      required String text
    }) {
      return SizedBox(
        width: 80,
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 14,
            ),
            const SizedBox(height: 5),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 12
              ),  
            )
          ]
        ),
      );
    }
    
    Widget generateLogStatus() {
      final filter = getFilteredStatus(context, appConfigProvider, log.reason, false);
      return logStatusWidget(
        icon: filter['icon'],
        color: filter['color'],
        text: filter['label'],
      );
    }

    String logClient() {
      if (appConfigProvider.showIpLogs == true) {
        return log.client;
      }
      else if (log.clientInfo != null && log.clientInfo!.name != "") {
        return log.clientInfo!.name;
      }
      else {
        return log.client;
      }
    }

    void blockUnblock({required String domain, required String newStatus}) async {
      final ProcessModal processModal = ProcessModal();
      processModal.open(AppLocalizations.of(context)!.savingUserFilters);

      final rules = await statusProvider.blockUnblockDomain(
        domain: domain,
        newStatus: newStatus
      );

      processModal.close();

      if (!context.mounted) return;
      if (rules == true) {
        showSnacbkar(
          appConfigProvider: appConfigProvider, 
          label: AppLocalizations.of(context)!.userFilteringRulesUpdated, 
          color: Colors.green
        );
      }
      else {
        showSnacbkar(
          appConfigProvider: appConfigProvider, 
          label: AppLocalizations.of(context)!.userFilteringRulesNotUpdated, 
          color: Colors.red
        );
      }
    }

    final domainBlocked = isDomainBlocked(log.reason);

    if (twoColumns && !(useAlwaysNormalTile == true)) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          child: OptionsMenu(
            onTap: (_) => onLogTap(log),
            borderRadius: BorderRadius.circular(28),
            options: (_) => [
              if (log.question.name != null) MenuOption(
                title: domainBlocked == true
                  ? AppLocalizations.of(context)!.unblockDomain
                  : AppLocalizations.of(context)!.blockDomain,
                icon: domainBlocked == true
                  ? Icons.check_rounded
                  : Icons.block_rounded, 
                action: () => blockUnblock(
                  domain: log.question.name!, 
                  newStatus: domainBlocked == true ? 'unblock' : 'block'
                )
              ),
              if (log.question.name != null) MenuOption(
                title: AppLocalizations.of(context)!.copyClipboard,
                icon: Icons.copy_rounded, 
                action: () => copyToClipboard(value: log.question.name!, successMessage: AppLocalizations.of(context)!.copiedClipboard)
              )
            ],
            child: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: isLogSelected == true
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.question.name ?? "N/A",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 5),
                              if (log.client.length <= 15 && appConfigProvider.showTimeLogs == false) Row(
                                children: [
                                  ...[
                                    Icon(
                                      Icons.smartphone_rounded,
                                      size: 16,
                                      color: Theme.of(context).listTileTheme.textColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        logClient(),
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Theme.of(context).listTileTheme.textColor,
                                          fontSize: 14,
                                          height: 1.4,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    )
                                  ],
                                  const SizedBox(width: 16),
                                  ...[
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 16,
                                      color: Theme.of(context).listTileTheme.textColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        convertTimestampLocalTimezone(log.time, 'HH:mm:ss'),
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Theme.of(context).listTileTheme.textColor,
                                          fontSize: 13
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (log.client.length > 15 || appConfigProvider.showTimeLogs == true) Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.smartphone_rounded,
                                        size: 16,
                                        color: Theme.of(context).listTileTheme.textColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          logClient(),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Theme.of(context).listTileTheme.textColor,
                                            fontSize: 13
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 16,
                                        color: Theme.of(context).listTileTheme.textColor,
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        child: Text(
                                          convertTimestampLocalTimezone(log.time, 'HH:mm:ss'),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Theme.of(context).listTileTheme.textColor,
                                            fontSize: 13
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  if (appConfigProvider.showTimeLogs == true && log.elapsedMs != '') ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.timer,
                                          size: 16,
                                          color: Theme.of(context).listTileTheme.textColor,
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          child: Text(
                                            "${double.parse(log.elapsedMs).toStringAsFixed(2)} ms",
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Theme.of(context).listTileTheme.textColor,
                                              fontSize: 13
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  generateLogStatus()
                ],
              )
            ),
          ),
        ),
      );
    }
    else {
      return Material(
        color: Colors.transparent,
        child: OptionsMenu(
          onTap: (_) => onLogTap(log),
          options: (_) => [
            if (log.question.name != null) MenuOption(
              title: domainBlocked == true
                ? AppLocalizations.of(context)!.unblockDomain
                : AppLocalizations.of(context)!.blockDomain,
              icon: domainBlocked == true
                ? Icons.check_rounded
                : Icons.block_rounded, 
              action: () => blockUnblock(
                domain: log.question.name!, 
                newStatus: domainBlocked == true ? 'unblock' : 'block'
              )
            ),
            if (log.question.name != null) MenuOption(
              title: AppLocalizations.of(context)!.copyClipboard,
              icon: Icons.copy_rounded, 
              action: () => copyToClipboard(
                value: log.question.name!, 
                successMessage: AppLocalizations.of(context)!.copiedClipboard
              )
            )
          ],
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.question.name ?? "N/A",
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurface
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (log.client.length <= 15 && appConfigProvider.showTimeLogs == false) Row(
                        children: [
                          ...[
                            Icon(
                              Icons.smartphone_rounded,
                              size: 16,
                              color: Theme.of(context).listTileTheme.textColor,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                logClient(),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context).listTileTheme.textColor,
                                  fontSize: 14,
                                  height: 1.4,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            )
                          ],
                          const SizedBox(width: 16),
                          ...[
                            Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: Theme.of(context).listTileTheme.textColor,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                convertTimestampLocalTimezone(log.time, 'HH:mm:ss'),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context).listTileTheme.textColor,
                                  fontSize: 13
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (log.client.length > 15 || appConfigProvider.showTimeLogs == true) Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.smartphone_rounded,
                                size: 16,
                                color: Theme.of(context).listTileTheme.textColor,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  logClient(),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Theme.of(context).listTileTheme.textColor,
                                    fontSize: 13
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 16,
                                    color: Theme.of(context).listTileTheme.textColor,
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    child: Text(
                                      convertTimestampLocalTimezone(log.time, 'HH:mm:ss'),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Theme.of(context).listTileTheme.textColor,
                                        fontSize: 13
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              if (appConfigProvider.showTimeLogs == true && log.elapsedMs != '') ...[
                                const SizedBox(width: 16),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      size: 16,
                                      color: Theme.of(context).listTileTheme.textColor,
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      child: Text(
                                        "${double.parse(log.elapsedMs).toStringAsFixed(2)} ms",
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Theme.of(context).listTileTheme.textColor,
                                          fontSize: 13
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                generateLogStatus()
              ],
            ),
          ),
        ),
      );
    }
  }
}