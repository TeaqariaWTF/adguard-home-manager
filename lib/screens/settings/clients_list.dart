// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:adguard_home_manager/screens/settings/add_client_modal.dart';
import 'package:adguard_home_manager/screens/clients/remove_client_modal.dart';

import 'package:adguard_home_manager/providers/app_config_provider.dart';
import 'package:adguard_home_manager/models/clients_allowed_blocked.dart';
import 'package:adguard_home_manager/providers/servers_provider.dart';
import 'package:adguard_home_manager/services/http_requests.dart';
import 'package:adguard_home_manager/classes/process_modal.dart';

class ClientsList extends StatefulWidget {
  final String type;
  final ScrollController scrollController;
  final int loadStatus;
  final List<String> data;
  final Future Function() fetchClients;

  const ClientsList({
    Key? key,
    required this.type,
    required this.scrollController,
    required this.loadStatus,
    required this.data,
    required this.fetchClients
  }) : super(key: key);

  @override
  State<ClientsList> createState() => _ClientsListState();
}

class _ClientsListState extends State<ClientsList> {
  late bool isVisible;

  @override
  initState(){
    super.initState();

    isVisible = true;
    widget.scrollController.addListener(() {
      if (mounted) {
        if (widget.scrollController.position.userScrollDirection == ScrollDirection.reverse) {
          if (mounted && isVisible == true) {
            setState(() => isVisible = false);
          }
        } 
        else {
          if (widget.scrollController.position.userScrollDirection == ScrollDirection.forward) {
            if (mounted && isVisible == false) {
              setState(() => isVisible = true);
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final serversProvider = Provider.of<ServersProvider>(context);
    final appConfigProvider = Provider.of<AppConfigProvider>(context);

    void confirmRemoveItem(String client, String type) async {
      Map<String, List<String>> body = {
        "allowed_clients": serversProvider.clients.data!.clientsAllowedBlocked?.allowedClients ?? [],
        "disallowed_clients": serversProvider.clients.data!.clientsAllowedBlocked?.disallowedClients ?? [],
        "blocked_hosts": serversProvider.clients.data!.clientsAllowedBlocked?.blockedHosts ?? [],
      };

      if (type == 'allowed') {
        body['allowed_clients'] = body['allowed_clients']!.where((c) => c != client).toList();
      }
      else if (type == 'disallowed') {
        body['disallowed_clients'] = body['disallowed_clients']!.where((c) => c != client).toList();
      }
      else if (type == 'domains') {
        body['blocked_hosts'] = body['blocked_hosts']!.where((c) => c != client).toList();
      }

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
        appConfigProvider.setShowingSnackbar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.clientAnotherList),
            backgroundColor: Colors.red,
          )
        );
      }
      else {
        appConfigProvider.addLog(result['log']);
        appConfigProvider.setShowingSnackbar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.clientNotRemoved),
            backgroundColor: Colors.red,
          )
        );
      }
    }

    void confirmAddItem(String item, String type) async {
      Map<String, List<String>> body = {
        "allowed_clients": serversProvider.clients.data!.clientsAllowedBlocked?.allowedClients ?? [],
        "disallowed_clients": serversProvider.clients.data!.clientsAllowedBlocked?.disallowedClients ?? [],
        "blocked_hosts": serversProvider.clients.data!.clientsAllowedBlocked?.blockedHosts ?? [],
      };

      if (type == 'allowed') {
        body['allowed_clients']!.add(item);
      }
      else if (type == 'disallowed') {
        body['disallowed_clients']!.add(item);
      }
      else if (type == 'domains') {
        body['blocked_hosts']!.add(item);
      }

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
        appConfigProvider.setShowingSnackbar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.clientAnotherList),
            backgroundColor: Colors.red,
          )
        );
      }
      else {
        appConfigProvider.addLog(result['log']);
        appConfigProvider.setShowingSnackbar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              type == 'allowed' || type == 'blocked'
                ? AppLocalizations.of(context)!.clientNotRemoved
                : AppLocalizations.of(context)!.domainNotAdded
            ),
            backgroundColor: Colors.red,
          )
        );
      }
    }

    String description() {
      switch (widget.type) {
        case 'allowed':
          return AppLocalizations.of(context)!.allowedClientsDescription;

        case 'disallowed':
          return AppLocalizations.of(context)!.blockedClientsDescription;

        case 'domains':
          return AppLocalizations.of(context)!.disallowedDomainsDescription;

        default:
          return "";
      }
    }

    String noItems() {
      switch (widget.type) {
        case 'allowed':
          return AppLocalizations.of(context)!.noAllowedClients;

        case 'disallowed':
          return AppLocalizations.of(context)!.noBlockedClients;

        case 'domains':
          return AppLocalizations.of(context)!.noDisallowedDomains;

        default:
          return "";
      }
    }

    switch (widget.loadStatus) {
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
                AppLocalizations.of(context)!.loadingClients,
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
            RefreshIndicator(
              onRefresh: widget.fetchClients,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Icon(Icons.info_rounded),
                            const SizedBox(width: 20),
                            SizedBox(
                              width: MediaQuery.of(context).size.width-112,
                              child: Text(description()),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (widget.data.isNotEmpty) Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 0),
                      itemCount: widget.data.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(widget.data[index]),
                        trailing: IconButton(
                          onPressed: () => {
                            showDialog(
                              context: context, 
                              builder: (context) => RemoveClientModal(
                                onConfirm: () => confirmRemoveItem(widget.data[index], widget.type),
                              )
                            )
                          }, 
                          icon: const Icon(Icons.delete_rounded)
                        ),
                      )
                    ),
                  ),
                  if (widget.data.isEmpty) Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          noItems(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.grey
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextButton.icon(
                          onPressed: widget.fetchClients, 
                          icon: const Icon(Icons.refresh_rounded), 
                          label: Text(AppLocalizations.of(context)!.refresh),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              bottom: isVisible ?
                appConfigProvider.showingSnackbar
                  ? 70 : 20
                : -70,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context, 
                    builder: (context) => AddClientModal(
                      type: widget.type,
                      onConfirm: confirmAddItem
                    ),
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true
                  );
                },
                child: const Icon(Icons.add),
              ),
            )
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
                AppLocalizations.of(context)!.clientsNotLoaded,
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