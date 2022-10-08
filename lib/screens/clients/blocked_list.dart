// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:adguard_home_manager/screens/clients/remove_domain_modal.dart';
import 'package:adguard_home_manager/screens/clients/fab.dart';

import 'package:adguard_home_manager/providers/app_config_provider.dart';
import 'package:adguard_home_manager/models/clients_allowed_blocked.dart';
import 'package:adguard_home_manager/providers/servers_provider.dart';
import 'package:adguard_home_manager/services/http_requests.dart';
import 'package:adguard_home_manager/classes/process_modal.dart';

class BlockedList extends StatelessWidget {
  final int loadStatus;
  final List<String> data;
  final Future Function() fetchClients;

  const BlockedList({
    Key? key,
    required this.loadStatus,
    required this.data,
    required this.fetchClients
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final serversProvider = Provider.of<ServersProvider>(context);
    final appConfigProvider = Provider.of<AppConfigProvider>(context);

    void confirmRemoveDomain(String domain) async {
      Map<String, List<String>> body = {
        "allowed_clients": serversProvider.clients.data!.clientsAllowedBlocked?.allowedClients ?? [],
        "disallowed_clients": serversProvider.clients.data!.clientsAllowedBlocked?.disallowedClients.where((client) => client != domain).toList() ?? [],
        "blocked_hosts": serversProvider.clients.data!.clientsAllowedBlocked?.blockedHosts ?? [],
      };

      ProcessModal processModal = ProcessModal(context: context);
      processModal.open(AppLocalizations.of(context)!.removingClient);

      final result = await requestAllowedBlockedClientsHosts(serversProvider.selectedServer!, body);

      processModal.close();

      if (result['result'] == 'success') {
        serversProvider.setAllowedDisallowedClientsBlockedDomains(
          ClientsAllowedBlocked(
            allowedClients: body['allowed_clients'] ?? [], 
            disallowedClients: body['disallowed_clients'] ?? [], 
            blockedHosts: body['blocked_hosts'] ?? [], 
          )
        );
      }
      else if (result['result'] == 'error' && result['message'] == 'client_another_list') {
        appConfigProvider.addLog(result['log']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.clientAnotherList),
            backgroundColor: Colors.red,
          )
        );
      }
      else {
        appConfigProvider.addLog(result['log']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.clientNotRemoved),
            backgroundColor: Colors.red,
          )
        );
      }
    }

    switch (loadStatus) {
      case 0:
         return SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height-171,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 30),
              Text(
                AppLocalizations.of(context)!.loadingStatus,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.grey,
                ),
              )
            ],
          ),
        );

      case 1: 
        return Stack(
          children: [
            if (data.isNotEmpty) ListView.builder(
              padding: const EdgeInsets.only(top: 0),
              itemCount: data.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(data[index]),
                trailing: IconButton(
                  onPressed: () => {
                    showDialog(
                      context: context, 
                      builder: (context) => RemoveDomainModal(
                        onConfirm: () => confirmRemoveDomain(data[index]),
                      )
                    )
                  }, 
                  icon: const Icon(Icons.delete_rounded)
                ),
              )
            ),
            if (data.isEmpty) SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.noCustomFilters,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.grey
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextButton.icon(
                    onPressed: fetchClients, 
                    icon: const Icon(Icons.refresh_rounded), 
                    label: Text(AppLocalizations.of(context)!.refresh),
                  )
                ],
              ),
            ),
            const Positioned(
              bottom: 20,
              right: 20,
              child: ClientsFab(tab: 2),
            ),
          ]
        );

      case 2: 
        return SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height-171,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.error,
                color: Colors.red,
                size: 50,
              ),
              const SizedBox(height: 30),
              Text(
                AppLocalizations.of(context)!.errorLoadServerStatus,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.grey,
                ),
              )
            ],
          ),
        );

      default:
        return const SizedBox();
    }

  }
}